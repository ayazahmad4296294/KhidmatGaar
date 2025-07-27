import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Type: ${booking['serviceType']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Location: ${booking['location']}'),
            Text('Amount: PKR ${booking['amount']}'),
            Text('Status: ${booking['status']}'),
            if (booking['notes'] != null) Text('Notes: ${booking['notes']}'),
          ],
        ),
      ),
    );
  }
}
