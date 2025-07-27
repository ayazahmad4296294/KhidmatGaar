import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class ScheduledServicesTab extends StatefulWidget {
  const ScheduledServicesTab({Key? key}) : super(key: key);

  @override
  State<ScheduledServicesTab> createState() => _ScheduledServicesTabState();
}

class _ScheduledServicesTabState extends State<ScheduledServicesTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<Booking> _scheduledBookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScheduledBookings();
  }

  Future<void> _loadScheduledBookings() async {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view scheduled services.';
      });
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: _auth.currentUser!.uid)
          .where('status', whereIn: [
            BookingStatus.confirmed.value,
            BookingStatus.rescheduled.value,
            BookingStatus.inProgress.value
          ])
          .orderBy('scheduledDateTime')
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        _scheduledBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading scheduled services: $e';
      });
    }
  }

  Future<void> _markAsInProgress(Booking booking) async {
    try {
      await _bookingService.updateBookingStatus(
          booking.id!, BookingStatus.inProgress);

      // Send notification to the customer
      await _notificationService.sendBookingUpdateNotification(
        userId: booking.userId,
        bookingId: booking.id!,
        serviceType: booking.serviceType,
        status: BookingStatus.inProgress.value,
      );

      _showSnackBar('Service marked as in progress');
      _loadScheduledBookings(); // Refresh the list
    } catch (e) {
      _showSnackBar('Error updating booking status: $e');
    }
  }

  Future<void> _markAsCompleted(Booking booking) async {
    try {
      await _bookingService.completeBooking(booking.id!);
      _showSnackBar('Service marked as completed');
      _loadScheduledBookings(); // Refresh the list
    } catch (e) {
      _showSnackBar('Error completing booking: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.purple));
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_scheduledBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No scheduled services',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group bookings by date
    final Map<String, List<Booking>> groupedBookings = {};

    for (var booking in _scheduledBookings) {
      final dateString =
          DateFormat('yyyy-MM-dd').format(booking.scheduledDateTime);
      if (!groupedBookings.containsKey(dateString)) {
        groupedBookings[dateString] = [];
      }
      groupedBookings[dateString]!.add(booking);
    }

    // Sort dates
    final sortedDates = groupedBookings.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadScheduledBookings,
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIndex) {
          final dateString = sortedDates[dateIndex];
          final date = DateTime.parse(dateString);
          final bookings = groupedBookings[dateString]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${bookings.length} service${bookings.length > 1 ? 's' : ''})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              ...bookings.map((booking) => _buildBookingCard(booking)).toList(),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final bool isInProgress = booking.status == BookingStatus.inProgress.value;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDisplayStatus(booking.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('hh:mm a').format(booking.scheduledDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Price: PKR ${booking.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${booking.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isInProgress) ...[
                  ElevatedButton.icon(
                    onPressed: () => _markAsInProgress(booking),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _markAsCompleted(booking),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.purple;
      case 'in_progress':
        return Colors.purple;
      case 'rescheduled':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
    }
  }
}
