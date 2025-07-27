import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import 'package:intl/intl.dart';

class RecentBookingsWidget extends StatefulWidget {
  final VoidCallback? onViewAll;

  const RecentBookingsWidget({
    Key? key,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<RecentBookingsWidget> createState() => _RecentBookingsWidgetState();
}

class _RecentBookingsWidgetState extends State<RecentBookingsWidget> {
  final List<Booking> _recentBookings = [];
  bool _isLoadingBookings = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _loadRecentBookings();
  }

  Future<void> _loadRecentBookings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoadingBookings = true;
      _bookingError = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(3)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        _recentBookings.clear();
        _recentBookings.addAll(bookings);
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() {
        _bookingError = 'Failed to load recent bookings';
        _isLoadingBookings = false;
      });
      print('Error loading bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_recentBookings.isNotEmpty && widget.onViewAll != null)
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Show loading indicator while fetching bookings
        if (_isLoadingBookings)
          const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          )
        // Show error message if there was an error
        else if (_bookingError != null)
          Center(
            child: Text(
              _bookingError!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        // Show message if no bookings found
        else if (_recentBookings.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No booking history found',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        // Show bookings list
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentBookings.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final booking = _recentBookings[index];
              return _buildBookingHistoryItem(booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingHistoryItem(Booking booking) {
    final formattedDate =
        DateFormat('dd MMM yyyy').format(booking.scheduledDateTime);
    final icon = _getServiceIcon(booking.serviceType);

    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        booking.serviceType,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text('$formattedDate • ${booking.workerName}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: booking.statusEnum.getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: booking.statusEnum.getStatusColor().withOpacity(0.5),
          ),
        ),
        child: Text(
          booking.statusEnum.name,
          style: TextStyle(
            color: booking.statusEnum.getStatusColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String title) {
    switch (title) {
      case 'Maid':
        return Icons.cleaning_services;
      case 'Cook':
        return Icons.restaurant;
      case 'Driver':
        return Icons.drive_eta;
      case 'Security Guard':
        return Icons.security;
      case 'Gardener':
        return Icons.grass;
      case 'Baby Care Taker':
        return Icons.child_care;
      case 'Handyman':
        return Icons.handyman;
      case 'Locksmith':
        return Icons.lock;
      case 'Auto Mechanic':
        return Icons.car_repair;
      case 'Chef':
        return Icons.restaurant;
      default:
        return Icons.work;
    }
  }
}
