import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/negotiation_service.dart';
import 'dart:math' as Math;
import '../l10n/app_localizations.dart';

class PendingBookingsTab extends StatefulWidget {
  const PendingBookingsTab({Key? key}) : super(key: key);

  @override
  State<PendingBookingsTab> createState() => _PendingBookingsTabState();
}

class _PendingBookingsTabState extends State<PendingBookingsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final NegotiationService _negotiationService = NegotiationService();
  bool _isLoading = true;
  List<Booking> _pendingBookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingBookings();
  }

  Future<void> _loadPendingBookings() async {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view pending bookings.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // First query regular pending bookings
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final allBookings = [];

      // Process each document
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        allBookings.add({
          'booking': Booking.fromMap(data, doc.id),
          'raw': data,
        });
      }

      // Filter for pending or negotiated bookings
      final pendingBookings = allBookings
          .where((item) =>
              item['booking'].status == BookingStatus.pending.value ||
              item['booking'].status == BookingStatus.confirmed.value &&
                  (item['raw']['negotiated'] == true &&
                      item['raw']['negotiationCompleted'] != true))
          .map((item) => item['booking'] as Booking)
          .toList();

      setState(() {
        _pendingBookings = pendingBookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading pending bookings: $e';
      });
    }
  }

  Future<void> _acceptBooking(Booking booking) async {
    try {
      await _bookingService.updateBookingStatus(
          booking.id!, BookingStatus.confirmed);

      // Send notification to the customer
      await _notificationService.sendBookingUpdateNotification(
        userId: booking.userId,
        bookingId: booking.id!,
        serviceType: booking.serviceType,
        status: BookingStatus.confirmed.value,
      );

      _showSnackBar('Booking accepted successfully');
      _loadPendingBookings(); // Refresh the list
    } catch (e) {
      _showSnackBar('Error accepting booking: $e');
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    try {
      await _bookingService.cancelBooking(booking.id!);
      _showSnackBar('Booking rejected successfully');
      _loadPendingBookings(); // Refresh the list
    } catch (e) {
      _showSnackBar('Error rejecting booking: $e');
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pending booking requests',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new booking requests will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingBookings,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _pendingBookings.length,
        itemBuilder: (context, index) {
          final booking = _pendingBookings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getServiceIcon(booking.serviceType),
                          color: _getServiceColor(booking.serviceType),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  _getTimeAgo(booking.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer info
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            radius: 16,
                            child: Icon(Icons.person,
                                size: 20, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Requested by: Customer',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Booking details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                                Icons.location_on, 'Location', booking.address),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today, 'Date & Time',
                                _formatDateTime(booking.scheduledDateTime)),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.payments, 'Price',
                                'PKR ${booking.price.toStringAsFixed(2)}',
                                isBold: true),
                            if (booking.notes != null &&
                                booking.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  Icons.note, 'Notes', booking.notes!),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptBooking(booking),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showStartNegotiationDialog(booking),
                              icon: const Icon(Icons.handshake, size: 18),
                              label: const Text('Negotiate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            radius: 20,
                            child: IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              onPressed: () =>
                                  _showRejectConfirmationDialog(booking),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'maid':
        return Icons.cleaning_services;
      case 'cook':
        return Icons.restaurant;
      case 'driver':
        return Icons.drive_eta;
      case 'security guard':
        return Icons.security;
      case 'gardener':
        return Icons.grass;
      case 'baby care taker':
        return Icons.child_care;
      case 'handyman':
        return Icons.handyman;
      case 'locksmith':
        return Icons.lock;
      case 'auto mechanic':
        return Icons.car_repair;
      case 'chef':
        return Icons.restaurant;
      default:
        return Icons.work;
    }
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'maid':
        return Colors.teal;
      case 'cook':
        return Colors.orange;
      case 'driver':
        return Colors.blue;
      case 'security guard':
        return Colors.red;
      case 'gardener':
        return Colors.green;
      case 'baby care taker':
        return Colors.purple;
      case 'handyman':
        return Colors.orange;
      case 'locksmith':
        return Colors.grey;
      case 'auto mechanic':
        return Colors.blue;
      case 'chef':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showAcceptConfirmationDialog(Booking booking) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Acceptance'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Are you sure you want to accept this booking request?'),
                const SizedBox(height: 8),
                Text('Service: ${booking.serviceType}'),
                Text('Date: ${_formatDateTime(booking.scheduledDateTime)}'),
                Text('Price: PKR ${booking.price.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Accept'),
              onPressed: () {
                Navigator.of(context).pop();
                _acceptBooking(booking);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRejectConfirmationDialog(Booking booking) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to reject this booking request? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reject'),
              onPressed: () {
                Navigator.of(context).pop();
                _rejectBooking(booking);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStartNegotiationDialog(Booking booking) async {
    final TextEditingController priceController =
        TextEditingController(text: booking.price.toStringAsFixed(2));
    final TextEditingController minPriceController = TextEditingController(
        text: (booking.price * 0.8).toStringAsFixed(2)); // 80% of original

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Price Negotiation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Enter your initial price offer and the minimum price you would accept:'),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Price Offer (PKR)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Acceptable Price (PKR)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Start Negotiation'),
              onPressed: () {
                // TODO: Implement negotiation start
                Navigator.of(context).pop();
                // Navigate to negotiation screen or start negotiation process
                _startNegotiation(
                  booking,
                  double.tryParse(priceController.text) ?? booking.price,
                  double.tryParse(minPriceController.text) ??
                      (booking.price * 0.8),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startNegotiation(
      Booking booking, double initialPrice, double minPrice) async {
    try {
      // Get market rates to set reasonable max price if needed
      final marketRates =
          await _negotiationService.getSuggestedPriceRange(booking.serviceType);

      // Validate initial price
      if (initialPrice <= 0) {
        initialPrice = booking.price; // Use original booking price if invalid
        _showSnackBar("Using original price as initial offer");
      }

      // Ensure minPrice is greater than 0 and less than initialPrice
      if (minPrice <= 0 || minPrice >= initialPrice) {
        minPrice = initialPrice * 0.8; // Default to 80% of initial price
        _showSnackBar("Minimum price set to ${minPrice.toStringAsFixed(2)}");
      }

      // Set a reasonable max price (either 20% above original or the market max rate, whichever is higher)
      double maxPrice = Math.max(
          initialPrice * 1.2,
          marketRates['maxMarketRate'] > 0
              ? marketRates['maxMarketRate']
              : initialPrice * 1.5);

      // Ensure maxPrice is greater than both initialPrice and minPrice
      if (maxPrice <= initialPrice) {
        maxPrice =
            initialPrice * 1.25; // Set max at least 25% above initial price
      }

      // Custom implementation of negotiation start for worker mode
      final now = DateTime.now();
      final negotiationData = {
        'bookingId': booking.id!,
        'workerId': _auth.currentUser!.uid,
        'customerId': booking.userId,
        'serviceName': booking.serviceType,
        'initialPrice': initialPrice,
        'minAcceptablePrice': minPrice,
        'maxAcceptablePrice': maxPrice,
        'currentOffer': initialPrice,
        'offerBy': 'worker', // Initial offer is from worker
        'isAccepted': false,
        'isRejected': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'offerHistory': [
          {
            'amount': initialPrice,
            'by': 'worker',
            'timestamp': Timestamp.fromDate(now),
            'message': 'Initial offer',
          }
        ],
      };

      // Directly add to Firestore instead of using the service method
      final docRef =
          await _firestore.collection('negotiations').add(negotiationData);
      final negotiationId = docRef.id;

      if (!mounted) return;

      // Get customer name for navigation
      final customerDoc =
          await _firestore.collection('users').doc(booking.userId).get();

      String customerName = 'Customer';
      if (customerDoc.exists) {
        final data = customerDoc.data();
        if (data != null) {
          customerName =
              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        }
      }

      // Send notification to customer about the negotiation
      await _notificationService.sendBookingUpdateNotification(
        userId: booking.userId,
        bookingId: booking.id!,
        serviceType: booking.serviceType,
        status: 'price negotiation started',
      );

      // Navigate to the negotiation screen
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/price-negotiation',
        arguments: {
          'negotiationId': negotiationId,
          'customerName': customerName,
        },
      );

      _showSnackBar('Negotiation started successfully');
    } catch (e) {
      _showSnackBar('Error starting negotiation: $e');
    }
  }
}
