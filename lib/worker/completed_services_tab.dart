import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../l10n/app_localizations.dart';

class CompletedServicesTab extends StatefulWidget {
  const CompletedServicesTab({Key? key}) : super(key: key);

  @override
  State<CompletedServicesTab> createState() => _CompletedServicesTabState();
}

class _CompletedServicesTabState extends State<CompletedServicesTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Booking> _completedBookings = [];
  String? _error;
  double _totalEarnings = 0.0;
  int _totalCompletedServices = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCompletedBookings();
  }

  Future<void> _loadCompletedBookings() async {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view completed services.';
      });
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: BookingStatus.completed.value)
          .orderBy('completedAt', descending: true)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate stats
      double totalEarnings = 0.0;
      for (var booking in bookings) {
        totalEarnings += booking.price;
      }

      setState(() {
        _completedBookings = bookings;
        _totalEarnings = totalEarnings;
        _totalCompletedServices = bookings.length;
        _isLoading = false;
      });

      // Load average rating separately
      _loadAverageRating();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading completed services.';
      });
    }
  }

  Future<void> _loadAverageRating() async {
    try {
      final workerId = _auth.currentUser!.uid;
      final ratingSnapshot =
          await _firestore.collection('workers').doc(workerId).get();

      if (ratingSnapshot.exists) {
        final data = ratingSnapshot.data();
        if (data != null && data.containsKey('rating')) {
          setState(() {
            _averageRating = (data['rating'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      print('Error loading average rating: $e');
    }
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildStatsCard(),
        ),
        if (_completedBookings.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No completed services yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Service History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return _buildBookingCard(_completedBookings[index - 1]);
              },
              childCount: _completedBookings.length + 1,
            ),
          ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.assignment_turned_in,
                  value: _totalCompletedServices.toString(),
                  label: 'Services',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.attach_money,
                  value: 'PKR ${_totalEarnings.toStringAsFixed(0)}',
                  label: 'Earnings',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.star,
                  value: _averageRating.toStringAsFixed(1),
                  label: 'Rating',
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(booking.scheduledDateTime),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('hh:mm a').format(booking.scheduledDateTime),
                  style: const TextStyle(fontSize: 14),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price: PKR ${booking.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (booking.completedAt != null)
                  Text(
                    'Completed on: ${DateFormat('dd/MM/yyyy').format(booking.completedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${booking.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
