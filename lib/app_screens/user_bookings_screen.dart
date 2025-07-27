// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import 'booking_details_screen.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import 'review_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();

  bool _isLoading = true;
  List<Booking> _pendingBookings = [];
  List<Booking> _activeBookings = [];
  List<Booking> _completedBookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view your bookings';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('scheduledDateTime', descending: true)
          .get();

      final bookings = [];

      // Parse bookings and add them to the list
      for (var doc in querySnapshot.docs) {
        bookings.add({
          'booking': Booking.fromMap(doc.data(), doc.id),
          'raw': doc.data(),
        });
      }

      final pending = bookings
          .where((item) =>
              item['booking'].status == BookingStatus.pending.value ||
              item['booking'].status == BookingStatus.confirmed.value ||
              item['booking'].status == BookingStatus.rescheduled.value ||
              (item['raw'].containsKey('negotiated') &&
                  item['raw']['negotiated'] == true))
          .map((item) => item['booking'] as Booking)
          .toList();

      final active = bookings
          .where((item) =>
              item['booking'].status == BookingStatus.inProgress.value)
          .map((item) => item['booking'] as Booking)
          .toList();

      final completed = bookings
          .where(
              (item) => item['booking'].status == BookingStatus.completed.value)
          .map((item) => item['booking'] as Booking)
          .toList();

      setState(() {
        _pendingBookings = pending;
        _activeBookings = active;
        _completedBookings = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading bookings: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.purple,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(_pendingBookings, 'No pending bookings'),
                    _buildBookingsList(_activeBookings, 'No active bookings'),
                    _buildBookingsList(
                        _completedBookings, 'No completed bookings'),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBookings,
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isCompleted = booking.status == BookingStatus.completed.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          booking.statusEnum.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: booking.statusEnum.getStatusColor(),
                      ),
                    ),
                    child: Text(
                      booking.statusEnum.name,
                      style: TextStyle(
                        color: booking.statusEnum.getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Worker: ${booking.workerName}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDateTime.day}/${booking.scheduledDateTime.month}/${booking.scheduledDateTime.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDateTime.hour}:${booking.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PKR ${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                  if (isCompleted)
                    FutureBuilder<bool>(
                      future: _reviewService.isBookingReviewed(booking.id!),
                      builder: (context, snapshot) {
                        final isReviewed = snapshot.data ?? false;
                        return TextButton.icon(
                          onPressed: () =>
                              _navigateToReviewScreen(booking, isReviewed),
                          icon: Icon(
                            isReviewed ? Icons.rate_review : Icons.star,
                            color: Colors.amber,
                          ),
                          label: Text(
                            isReviewed ? 'View Review' : 'Leave Review',
                            style: const TextStyle(color: Colors.amber),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewBookingDetails(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(
          bookingId: booking.id!,
        ),
      ),
    ).then((_) => _loadBookings());
  }

  void _navigateToReviewScreen(Booking booking, bool isReviewed) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          booking: booking,
          isReviewed: isReviewed,
        ),
      ),
    );

    if (result == true) {
      // Refresh the bookings after review is submitted
      _loadBookings();
    }
  }
}
