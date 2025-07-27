// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = true;
  List<Booking> _bookings = [];
  String? _error;
  Stream<List<Booking>>? _bookingsStream;

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

  void _loadBookings() {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view your bookings';
      });
      return;
    }

    try {
      setState(() {
        _bookingsStream = _bookingService.getUserBookings();
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Bookings',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.purple.shade700,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: Colors.purple.shade700,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Past'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple))
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : _bookingsStream == null
                        ? const Center(
                            child: Text(
                              'Unable to load bookings',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : StreamBuilder<List<Booking>>(
                            stream: _bookingsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No bookings found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }

                              final bookings = snapshot.data!;

                              return TabBarView(
                                controller: _tabController,
                                children: [
                                  // All bookings
                                  _buildBookingList(bookings),

                                  // Active bookings (pending, confirmed, in_progress)
                                  _buildBookingList(bookings
                                      .where((booking) =>
                                          booking.status ==
                                              BookingStatus.pending.value ||
                                          booking.status ==
                                              BookingStatus.confirmed.value ||
                                          booking.status ==
                                              BookingStatus.inProgress.value)
                                      .toList()),

                                  // Past bookings (completed, cancelled)
                                  _buildBookingList(bookings
                                      .where((booking) =>
                                          booking.status ==
                                              BookingStatus.completed.value ||
                                          booking.status ==
                                              BookingStatus.cancelled.value)
                                      .toList()),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _refreshBookings(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings in this category'));
    }

    return ListView.builder(
      itemCount: bookings.length,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            title: Text(
              booking.serviceType,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      booking.workerName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(booking.scheduledDateTime),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Status: ${booking.status}',
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PKR ${booking.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.purple,
                ),
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/booking-details',
                arguments: booking.id,
              ).then((_) => _refreshBookings());
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade800;
      case 'confirmed':
        return Colors.blue.shade800;
      case 'in_progress':
        return Colors.purple.shade800;
      case 'completed':
        return Colors.green.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _refreshBookings() {
    setState(() {
      _isLoading = true;
      _error = null;
      _bookingsStream = null;
    });
    _loadBookings();
  }
}
