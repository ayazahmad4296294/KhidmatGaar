import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug print to verify notification data
    print(
        'Building NotificationItem: id=${notification.id}, title=${notification.title}, isRead=${notification.isRead}');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Colors.blue.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      // Customer notifications
      case NotificationType.bookingConfirmation:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.bookingUpdate:
        iconData = Icons.update;
        iconColor = Colors.blue;
        break;
      case NotificationType.bookingCancellation:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;

      // Worker notifications
      case NotificationType.newBookingRequest:
        iconData = Icons.notifications_active;
        iconColor = Colors.purple;
        break;
      case NotificationType.bookingStatusChange:
        iconData = Icons.sync;
        iconColor = Colors.teal;
        break;
      case NotificationType.negotiationRequest:
        iconData = Icons.handshake;
        iconColor = Colors.amber;
        break;

      // Both
      case NotificationType.promotional:
        iconData = Icons.campaign;
        iconColor = Colors.orange;
        break;
      case NotificationType.system:
      default:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
