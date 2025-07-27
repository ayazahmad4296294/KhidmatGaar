import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../utils/user_mode.dart';
import '../main.dart'; // Import for navigatorKey

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification channel ID
  static const String _channelId = 'high_importance_channel';

  // Notification initialization
  Future<void> init() async {
    // Initialize awesome notifications
    await _initAwesomeNotifications();

    // Request permission for notifications
    await _requestPermission();

    // Get FCM token
    await _getFcmToken();

    // Set up message handlers
    _setupForegroundMessageHandler();
    _setupBackgroundMessageHandler();
    _setupMessageOpenedAppHandler();
  }

  // Initialize awesome notifications
  Future<void> _initAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // no icon for now, customize as needed
      [
        NotificationChannel(
          channelKey: _channelId,
          channelName: 'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
        )
      ],
      debug: true,
    );

    // Listen for notification actions/taps
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
    );
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    // Request permissions from Firebase Messaging
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Firebase permission: ${settings.authorizationStatus}');

    // Request awesome notifications permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Handle when notification action is received
  @pragma('vm:entry-point')
  static Future<void> _onNotificationActionReceived(
      ReceivedAction receivedAction) async {
    if (receivedAction.payload != null) {
      // Get instance of NotificationService to handle the action
      final notificationService = NotificationService();
      // Handle notification tap based on type and data
      notificationService._handleNotificationTap(
          Map<String, dynamic>.from(receivedAction.payload!));
    }
  }

  // Get FCM token and save to user document
  Future<void> _getFcmToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _saveTokenToDatabase(userId, token);
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          _saveTokenToDatabase(userId, newToken);
        }
      });
    }
  }

  // Save FCM token to user document
  Future<void> _saveTokenToDatabase(String userId, String token) async {
    // First, check if this is a worker or customer
    bool isWorker = await UserMode.isWorkerMode();

    // Save to appropriate collection
    if (isWorker) {
      await _firestore.collection('workers').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
      });
    } else {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
      });
    }
  }

  // Set up foreground message handler
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show a local notification
      _showAwesomeNotification(message);

      // Save the notification to Firestore
      _saveNotificationToFirestore(message);
    });
  }

  // Set up background message handler
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Handle notification opening the app
  void _setupMessageOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });
  }

  // Show a local notification using awesome_notifications
  Future<void> _showAwesomeNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      final Map<String, String?> payload = {};
      message.data.forEach((key, value) {
        payload[key] = value?.toString();
      });

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification.hashCode,
          channelKey: _channelId,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: payload,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final userId = message.data['userId'] ?? _auth.currentUser?.uid;
    if (userId == null) return;

    final userRole = message.data['targetUserRole'] == 'worker'
        ? UserRole.worker
        : UserRole.customer;

    final notification = AppNotification(
      id: '', // Will be assigned by Firestore
      userId: userId,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: _getNotificationType(message.data['type']),
      timestamp: DateTime.now(),
      data: message.data,
      targetUserRole: userRole,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Get notification type from string
  NotificationType _getNotificationType(String? type) {
    if (type == null) return NotificationType.system;

    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.$type',
        orElse: () => NotificationType.system,
      );
    } catch (e) {
      // Legacy mapping for backwards compatibility
      switch (type) {
        case 'bookingAlert':
          return NotificationType.bookingUpdate;
        case 'workerAlert':
          return NotificationType.bookingStatusChange;
        case 'promotional':
          return NotificationType.promotional;
        default:
          return NotificationType.system;
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Implement navigation logic based on notification type and data
    final type = data['type'];
    final context = _getGlobalContext();

    if (context != null) {
      final bool isWorkerNotification = data['targetUserRole'] == 'worker';

      // Different navigation based on target user role
      if (isWorkerNotification) {
        _handleWorkerNotificationTap(context, type, data);
      } else {
        _handleCustomerNotificationTap(context, type, data);
      }
    }
  }

  // Handle worker-specific notification taps
  void _handleWorkerNotificationTap(
      BuildContext context, String? type, Map<String, dynamic> data) {
    switch (type) {
      case 'newBookingRequest':
      case 'bookingStatusChange':
        if (data['bookingId'] != null) {
          Navigator.of(context).pushNamed(
            '/booking-details',
            arguments: data['bookingId'],
          );
        }
        break;
      case 'negotiationRequest':
        if (data['negotiationId'] != null) {
          Navigator.of(context).pushNamed(
            '/price-negotiation',
            arguments: {
              'negotiationId': data['negotiationId'],
              'customerName': data['customerName'] ?? 'Customer',
            },
          );
        }
        break;
      default:
        Navigator.of(context).pushNamed('/notifications');
    }
  }

  // Handle customer-specific notification taps
  void _handleCustomerNotificationTap(
      BuildContext context, String? type, Map<String, dynamic> data) {
    switch (type) {
      case 'bookingConfirmation':
      case 'bookingUpdate':
      case 'bookingCancellation':
        if (data['bookingId'] != null) {
          Navigator.of(context).pushNamed(
            '/booking-details',
            arguments: data['bookingId'],
          );
        }
        break;
      case 'promotional':
        Navigator.of(context).pushNamed('/promotions');
        break;
      default:
        Navigator.of(context).pushNamed('/notifications');
    }
  }

  // Get application global context
  BuildContext? _getGlobalContext() {
    // Use the navigator key from main.dart
    return navigatorKey.currentContext;
  }

  // Get user notifications
  Stream<List<AppNotification>> getUserNotifications(
      {UserRole? targetRole}) async* {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      yield [];
      return;
    }

    try {
      // Start with a query for this user's notifications
      Query notificationsQuery = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      // If targetRole is specified, filter by that role
      if (targetRole != null) {
        String roleString =
            targetRole == UserRole.worker ? 'worker' : 'customer';
        notificationsQuery =
            notificationsQuery.where('targetUserRole', isEqualTo: roleString);
      }

      yield* notificationsQuery.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return AppNotification.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error getting notifications: $e');
      yield [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Determine if we're in worker or customer mode
    final isWorkerMode = await UserMode.isWorkerMode();
    final targetRole = isWorkerMode ? 'worker' : 'customer';

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('targetUserRole', isEqualTo: targetRole)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return 0;
    }

    try {
      // Determine user role
      final isWorker = await UserMode.isWorkerMode();
      final userRoleString = isWorker ? 'worker' : 'customer';

      // Query for unread notifications for this user with the correct role
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('targetUserRole', isEqualTo: userRoleString)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Customer Notifications

  // Send booking confirmation notification
  Future<void> sendBookingConfirmationNotification({
    required String userId,
    required String bookingId,
    required String serviceType,
    required DateTime bookingTime,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: 'Booking Confirmed',
      body:
          'Your $serviceType booking for ${_formatDateTime(bookingTime)} has been confirmed.',
      type: NotificationType.bookingConfirmation,
      timestamp: DateTime.now(),
      data: {
        'type': 'bookingConfirmation',
        'bookingId': bookingId,
        'targetUserRole': 'customer'
      },
      targetUserRole: UserRole.customer,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send booking update notification to customer
  Future<void> sendBookingUpdateNotification({
    required String userId,
    required String bookingId,
    required String serviceType,
    required String status,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: 'Booking Update',
      body: 'Your $serviceType booking status has been updated to $status.',
      type: NotificationType.bookingUpdate,
      timestamp: DateTime.now(),
      data: {
        'type': 'bookingUpdate',
        'bookingId': bookingId,
        'targetUserRole': 'customer'
      },
      targetUserRole: UserRole.customer,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send booking cancellation notification to customer
  Future<void> sendBookingCancellationNotification({
    required String userId,
    required String bookingId,
    required String serviceType,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: 'Booking Cancelled',
      body: 'Your $serviceType booking has been cancelled.',
      type: NotificationType.bookingCancellation,
      timestamp: DateTime.now(),
      data: {
        'type': 'bookingCancellation',
        'bookingId': bookingId,
        'targetUserRole': 'customer'
      },
      targetUserRole: UserRole.customer,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Worker Notifications

  // Send new booking request notification to worker
  Future<void> sendNewBookingRequestNotification({
    required String workerId,
    required String bookingId,
    required String customerName,
    required String serviceType,
    required DateTime bookingTime,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: workerId,
      title: 'New Booking Request',
      body:
          'You have a new $serviceType booking request from $customerName for ${_formatDateTime(bookingTime)}.',
      type: NotificationType.newBookingRequest,
      timestamp: DateTime.now(),
      data: {
        'type': 'newBookingRequest',
        'bookingId': bookingId,
        'customerName': customerName,
        'targetUserRole': 'worker'
      },
      targetUserRole: UserRole.worker,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send booking status change notification to worker
  Future<void> sendBookingStatusChangeNotification({
    required String workerId,
    required String bookingId,
    required String customerName,
    required String serviceType,
    required String status,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: workerId,
      title: 'Booking Status Changed',
      body:
          'Booking from $customerName for $serviceType has been changed to $status.',
      type: NotificationType.bookingStatusChange,
      timestamp: DateTime.now(),
      data: {
        'type': 'bookingStatusChange',
        'bookingId': bookingId,
        'customerName': customerName,
        'targetUserRole': 'worker'
      },
      targetUserRole: UserRole.worker,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send negotiation request notification to worker
  Future<void> sendNegotiationRequestNotification({
    required String workerId,
    required String negotiationId,
    required String customerName,
    required String serviceType,
    required double proposedPrice,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: workerId,
      title: 'New Price Negotiation',
      body:
          '$customerName has requested a price negotiation for $serviceType (PKR ${proposedPrice.toStringAsFixed(0)}).',
      type: NotificationType.negotiationRequest,
      timestamp: DateTime.now(),
      data: {
        'type': 'negotiationRequest',
        'negotiationId': negotiationId,
        'customerName': customerName,
        'targetUserRole': 'worker'
      },
      targetUserRole: UserRole.worker,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send promotional notification to any user role
  Future<void> sendPromotionalNotification({
    required String userId,
    required String title,
    required String body,
    required UserRole targetUserRole,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.promotional,
      timestamp: DateTime.now(),
      data: {
        'type': 'promotional',
        'targetUserRole':
            targetUserRole == UserRole.worker ? 'worker' : 'customer',
        ...?data,
      },
      targetUserRole: targetUserRole,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Send worker booking alert notification
  Future<void> sendWorkerBookingAlert({
    required String workerId,
    required String bookingId,
    required String customerName,
    required String serviceType,
    required DateTime bookingTime,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: workerId,
      title: 'New Booking Alert',
      body:
          '$customerName has booked your $serviceType service for ${_formatDateTime(bookingTime)}.',
      type: NotificationType.newBookingRequest,
      timestamp: DateTime.now(),
      data: {
        'type': 'newBookingRequest',
        'bookingId': bookingId,
        'customerName': customerName,
        'targetUserRole': 'worker'
      },
      targetUserRole: UserRole.worker,
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Helper method to format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Send a test notification (for development and testing)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    required NotificationType type,
    required UserRole targetUserRole,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Create an in-app notification in Firestore
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: {
        'type': type.toString().split('.').last,
        'targetUserRole':
            targetUserRole == UserRole.worker ? 'worker' : 'customer',
        'test': true,
      },
      targetUserRole: targetUserRole,
    );

    await _firestore.collection('notifications').add(notification.toMap());

    // Also show a local notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _channelId,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: {
          'type': type.toString().split('.').last,
          'targetUserRole':
              targetUserRole == UserRole.worker ? 'worker' : 'customer',
          'test': 'true',
        },
      ),
    );
  }
}

// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized here as well
  // This would normally be done in the main.dart file

  // Save notification to Firestore
  final firestore = FirebaseFirestore.instance;
  final userId = message.data['userId'];

  if (userId != null) {
    final userRole =
        message.data['targetUserRole'] == 'worker' ? 'worker' : 'customer';

    final notification = {
      'userId': userId,
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': message.data,
      'targetUserRole': userRole,
    };

    await firestore.collection('notifications').add(notification);
  }
}
