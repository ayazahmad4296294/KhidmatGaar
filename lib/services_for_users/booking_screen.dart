// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/loyalty_service.dart';
import 'booking_detail_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final LoyaltyService _loyaltyService = LoyaltyService();
  late TabController _tabController;
  bool _isLoading = false;
  int _availablePoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoyaltyPoints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoyaltyPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _loyaltyService.getUserPointsSummary();
      setState(() {
        _availablePoints = summary.availablePoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading loyalty points: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingBookings(),
          _buildCompletedBookings(),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    print("DEBUG: BookingScreen - Building Upcoming Bookings view");
    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getUpcomingBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("DEBUG: BookingScreen - Waiting for upcoming bookings data");
          return const Center(child: CircularProgressIndicator(color: Colors.purple));
        }

        if (snapshot.hasError) {
          print(
              "DEBUG: BookingScreen - Error loading upcoming bookings: ${snapshot.error}");
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];
        print(
            "DEBUG: BookingScreen - Loaded ${bookings.length} upcoming bookings");

        if (bookings.isNotEmpty) {
          // Debug each booking
          for (var booking in bookings) {
            print("DEBUG: Booking ID: ${booking.id}");
            print("DEBUG: - Service: ${booking.serviceType}");
            print("DEBUG: - Status: ${booking.status}");
            print("DEBUG: - Date: ${booking.scheduledDateTime}");
            print("DEBUG: - Worker: ${booking.workerName}");
          }
        }

        if (bookings.isEmpty) {
          print("DEBUG: BookingScreen - No upcoming bookings found");
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No upcoming bookings',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Schedule a service to get started',
                  style: TextStyle(color: Colors.grey),
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
      },
    );
  }

  Widget _buildCompletedBookings() {
    print("DEBUG: BookingScreen - Building Completed Bookings view");
    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getCompletedBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("DEBUG: BookingScreen - Waiting for completed bookings data");
          return const Center(child: CircularProgressIndicator(color: Colors.purple));
        }

        if (snapshot.hasError) {
          print(
              "DEBUG: BookingScreen - Error loading completed bookings: ${snapshot.error}");
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];
        print(
            "DEBUG: BookingScreen - Loaded ${bookings.length} completed bookings");

        if (bookings.isEmpty) {
          print("DEBUG: BookingScreen - No completed bookings found");
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No completed bookings',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(booking.scheduledDateTime);
    final formattedTime = timeFormat.format(booking.scheduledDateTime);

    // Determine color based on status
    final statusColor = booking.statusEnum.getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(
                bookingId: booking.id!,
                availablePoints: _availablePoints,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      booking.statusEnum.name,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Worker: ${booking.workerName}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Time: $formattedTime',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Address: ${booking.address}',
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PKR ${booking.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  if (booking.loyaltyPointsEarned != null &&
                      booking.loyaltyPointsEarned! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '+${booking.loyaltyPointsEarned} points',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
