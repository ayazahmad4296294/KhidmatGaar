import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: _demoNotifications.length,
        itemBuilder: (context, index) {
          final notification = _demoNotifications[index];
          return NotificationTile(notification: notification);
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const NotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read
            ? Colors.grey.shade200
            : Theme.of(context).primaryColor.withOpacity(0.2),
        child: Icon(
          notification.icon,
          color: notification.read ? Colors.grey : Colors.purple,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(
            notification.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        // Handle notification tap
      },
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final bool read;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    this.read = false,
  });
}

final List<NotificationItem> _demoNotifications = [
  NotificationItem(
    title: 'Booking Confirmed',
    message: 'Your booking for Security Guard service has been confirmed.',
    timeAgo: '2 minutes ago',
    icon: Icons.check_circle,
  ),
  NotificationItem(
    title: 'Special Offer',
    message: '20% off on Monthly Security Guard Service!',
    timeAgo: '1 hour ago',
    icon: Icons.local_offer,
    read: true,
  ),
  NotificationItem(
    title: 'Service Reminder',
    message: 'Your Driver service is scheduled for tomorrow.',
    timeAgo: '3 hours ago',
    icon: Icons.access_time,
  ),
  NotificationItem(
    title: 'Payment Success',
    message: 'Payment received for Maid service.',
    timeAgo: '1 day ago',
    icon: Icons.payment,
    read: true,
  ),
];
