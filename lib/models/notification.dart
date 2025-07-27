import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  // Customer notifications
  bookingConfirmation, // Booking has been confirmed
  bookingUpdate, // Booking status changed
  bookingCancellation, // Booking has been cancelled

  // Worker notifications
  newBookingRequest, // New booking request received
  bookingStatusChange, // Customer changed booking status
  negotiationRequest, // New price negotiation

  // Both
  promotional, // Marketing/promotional notifications
  system // System notifications
}

enum UserRole { customer, worker }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final UserRole
      targetUserRole; // Added to indicate which role this notification is for

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    required this.targetUserRole,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseNotificationType(map['type']),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
      targetUserRole: map['targetUserRole'] == 'worker'
          ? UserRole.worker
          : UserRole.customer,
    );
  }

  static NotificationType _parseNotificationType(String? value) {
    if (value == null) return NotificationType.system;

    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.$value',
        orElse: () => NotificationType.system,
      );
    } catch (e) {
      // Legacy mapping for backwards compatibility
      switch (value) {
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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
      'targetUserRole':
          targetUserRole == UserRole.worker ? 'worker' : 'customer',
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    UserRole? targetUserRole,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      targetUserRole: targetUserRole ?? this.targetUserRole,
    );
  }
}
