import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_item.dart';
import '../utils/user_mode.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWorkerMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTabController();

    // Manually refresh notifications when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
    });
  }

  Future<void> _initializeTabController() async {
    final isWorker = await UserMode.isWorkerMode();

    setState(() {
      _isWorkerMode = isWorker;
      _tabController = TabController(length: 3, vsync: this);
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notificationCount = notificationProvider.notifications.length;
        final unreadCount = notificationProvider.unreadCount;

        print(
            'NotificationsScreen: Total notifications: $notificationCount, Unread: $unreadCount');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (notificationProvider.unreadCount > 0)
                TextButton(
                  onPressed: () => notificationProvider.markAllAsRead(),
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: _isWorkerMode
                  ? const [
                      // Worker mode tabs
                      Tab(text: 'All'),
                      Tab(text: 'Bookings'),
                      Tab(text: 'Negotiations'),
                    ]
                  : const [
                      // Customer mode tabs
                      Tab(text: 'All'),
                      Tab(text: 'Bookings'),
                      Tab(text: 'Promotions'),
                    ],
            ),
          ),
          body: notificationProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.purple))
              : TabBarView(
                  controller: _tabController,
                  children: _isWorkerMode
                      ? [
                          // Worker mode tab content
                          _buildNotificationsList(
                              notificationProvider.notifications),

                          // Booking-related notifications (new requests, status changes)
                          _buildNotificationsList([
                            ...notificationProvider.getFilteredNotifications(
                                NotificationType.newBookingRequest),
                            ...notificationProvider.getFilteredNotifications(
                                NotificationType.bookingStatusChange),
                          ]),

                          // Negotiation notifications
                          _buildNotificationsList(
                            notificationProvider.getFilteredNotifications(
                                NotificationType.negotiationRequest),
                          ),
                        ]
                      : [
                          // Customer mode tab content
                          _buildNotificationsList(
                              notificationProvider.notifications),

                          // Booking-related notifications
                          _buildNotificationsList([
                            ...notificationProvider.getFilteredNotifications(
                                NotificationType.bookingConfirmation),
                            ...notificationProvider.getFilteredNotifications(
                                NotificationType.bookingUpdate),
                            ...notificationProvider.getFilteredNotifications(
                                NotificationType.bookingCancellation),
                          ]),

                          // Promotional notifications
                          _buildNotificationsList(
                            notificationProvider.getFilteredNotifications(
                                NotificationType.promotional),
                          ),
                        ],
                ),
        );
      },
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh notifications when pulled down
        await Provider.of<NotificationProvider>(context, listen: false)
            .refreshNotifications();
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () {
              // Mark as read when tapped
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAsRead(notification.id);

              // Navigate based on notification type and data
              _handleNotificationTap(notification);
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    final data = notification.data;
    if (data == null) return;

    // Use the appropriate handler based on user role
    if (_isWorkerMode) {
      _handleWorkerNotificationTap(notification);
    } else {
      _handleCustomerNotificationTap(notification);
    }
  }

  void _handleWorkerNotificationTap(AppNotification notification) {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.newBookingRequest:
      case NotificationType.bookingStatusChange:
        if (data['bookingId'] != null) {
          Navigator.pushNamed(
            context,
            '/booking-details',
            arguments: data['bookingId'],
          );
        }
        break;
      case NotificationType.negotiationRequest:
        if (data['negotiationId'] != null) {
          Navigator.pushNamed(
            context,
            '/price-negotiation',
            arguments: {
              'negotiationId': data['negotiationId'],
              'customerName': data['customerName'] ?? 'Customer',
            },
          );
        }
        break;
      default:
        // No action for other notification types
        break;
    }
  }

  void _handleCustomerNotificationTap(AppNotification notification) {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.bookingConfirmation:
      case NotificationType.bookingUpdate:
      case NotificationType.bookingCancellation:
        if (data['bookingId'] != null) {
          Navigator.pushNamed(
            context,
            '/booking-details',
            arguments: data['bookingId'],
          );
        }
        break;
      case NotificationType.promotional:
        // Navigate to promotions page if applicable
        break;
      default:
        // No action for other notification types
        break;
    }
  }
}
