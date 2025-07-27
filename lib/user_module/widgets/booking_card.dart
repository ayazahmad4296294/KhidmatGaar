import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          booking['serviceName'] ?? 'Unknown Service',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${booking['status'] ?? 'Unknown'}'),
            Text('Price: Rs.${booking['price'] ?? '0'}'),
            if (booking['scheduledTime'] != null)
              Text('Scheduled: ${booking['scheduledTime']}'),
          ],
        ),
        trailing: booking['status'] == 'pending'
            ? TextButton(
                onPressed: () {
                  // Add cancel booking logic
                },
                child: const Text('Cancel'),
              )
            : null,
      ),
    );
  }
}
