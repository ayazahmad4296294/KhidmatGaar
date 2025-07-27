import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'price_negotiation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../app_screens/home_page.dart';
import '../chat/start_chat_button.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';

class WorkerDetailPage extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String serviceName;

  const WorkerDetailPage({
    super.key,
    required this.worker,
    required this.serviceName,
  });

  @override
  State<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends State<WorkerDetailPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _reviews = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get reviews for this worker
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('workerId', isEqualTo: widget.worker['id'])
          .orderBy('createdAt', descending: true) // Sort by newest first
          .limit(10) // Increased from 5 to 10 reviews
          .get();

      print(
          'DEBUG: Found ${reviewsSnapshot.docs.length} reviews for worker ${widget.worker['id']}');

      final reviews = reviewsSnapshot.docs.map((doc) {
        final data = doc.data();
        print('DEBUG: Review document ID: ${doc.id}');
        print('DEBUG: Review data: $data');
        print('DEBUG: Comment value: "${data['comment']}"');

        final createdAt = data['createdAt'];

        return {
          'id': doc.id,
          'customerId': data['customerId'] ?? '',
          'customerName': data['customerName'] ?? 'Anonymous',
          'rating': (data['rating'] ?? 3.0).toDouble(),
          'comment': data['comment'] ?? '',
          'serviceType': data['serviceType'] ?? 'Service',
          'date':
              (createdAt is Timestamp) ? createdAt.toDate() : DateTime.now(),
        };
      }).toList();

      print('DEBUG: Processed reviews: $reviews');

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startPriceNegotiation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to negotiate price')),
      );
      return;
    }

    // Get the location provider
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    // Try to get current location if we don't have one already
    if (locationProvider.currentAddress == 'Your location') {
      await locationProvider.getCurrentLocation();
    }

    // Create a unique booking ID for this negotiation
    final bookingId = _firestore.collection('bookings').doc().id;
    print("DEBUG: Generated booking ID for negotiation: $bookingId");

    // Determine initial price based on service type
    double initialPrice = 0.0;
    switch (widget.serviceName) {
      case 'Maid':
        initialPrice = 2500.0;
        break;
      case 'Cook':
        initialPrice = 3000.0;
        break;
      case 'Driver':
        initialPrice = 2800.0;
        break;
      case 'Security Guard':
        initialPrice = 3500.0;
        break;
      case 'Baby Care Taker':
        initialPrice = 4000.0;
        break;
      case 'Gardener':
        initialPrice = 2200.0;
        break;
      case 'Handyman':
        initialPrice = 3200.0;
        break;
      case 'Locksmith':
        initialPrice = 4500.0;
        break;
      case 'Auto Mechanic':
        initialPrice = 3800.0;
        break;
      case 'Chef':
        initialPrice = 5000.0;
        break;
      default:
        initialPrice = 3000.0;
    }

    // Fetch or create market rates for this service
    await _firestore
        .collection('market_rates')
        .where('serviceName', isEqualTo: widget.serviceName)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Create new market rate entry if none exists
        _firestore.collection('market_rates').add({
          'serviceName': widget.serviceName,
          'minRate': initialPrice * 0.9,
          'avgRate': initialPrice,
          'maxRate': initialPrice * 1.3,
          'updatedAt': Timestamp.now(),
        });
      }
    }).catchError((error) {
      print('Error checking market rates: $error');
    });

    // Open negotiation screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceNegotiationScreen(
          workerId: widget.worker['id'],
          workerName: widget.worker['name'],
          serviceName: widget.serviceName,
          bookingId: bookingId,
          initialPrice: initialPrice,
        ),
      ),
    );

    // Handle negotiation result
    if (result != null && result['accepted'] == true) {
      final finalPrice = result['finalPrice'];
      print("DEBUG: Negotiation accepted with final price: $finalPrice");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Price agreed: PKR ${finalPrice.toStringAsFixed(2)}')),
      );

      // Get user's current address from result or LocationProvider
      String currentAddress =
          result['address'] ?? locationProvider.currentAddress;
      String fullAddress =
          result['fullAddress'] ?? locationProvider.fullAddress;
      print("DEBUG: Using address: $currentAddress");

      // Schedule for tomorrow by default
      DateTime scheduledDateTime = DateTime.now().add(const Duration(days: 1));
      print("DEBUG: Scheduled for: $scheduledDateTime");

      // Create a complete booking object with all required fields
      final booking = {
        'userId': user.uid,
        'workerId': widget.worker['id'],
        'workerName': widget.worker['name'],
        'serviceType': widget.serviceName,
        'address': currentAddress,
        'fullAddress': fullAddress,
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'status': BookingStatus.pending.value,
        'price': finalPrice,
        'discountAmount': 0.0,
        'notes': 'Created from negotiation',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isPaid': false,
        'paymentMethod': 'cash',
        'isReviewed': false,
      };

      print("DEBUG: Created booking data: $booking");

      // Save the booking to Firestore
      print("DEBUG: Saving booking to Firestore...");
      _firestore.collection('bookings').doc(bookingId).set(booking).then((_) {
        print("DEBUG: Booking saved successfully!");

        // Verify the booking was created
        _firestore
            .collection('bookings')
            .doc(bookingId)
            .get()
            .then((docSnapshot) {
          if (docSnapshot.exists) {
            print("DEBUG: Verified booking exists in Firestore");
            final savedData = docSnapshot.data();
            print("DEBUG: Saved data: $savedData");
          } else {
            print(
                "DEBUG: WARNING! Booking verification failed - document does not exist in Firestore");
          }
        }).catchError((error) {
          print("DEBUG: ERROR verifying booking: $error");
        });

        // Show booking created message with options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking created successfully!'),
            action: SnackBarAction(
              label: 'VIEW BOOKINGS',
              onPressed: () {
                // Navigate to the bookings tab
                HomePage.navigateToBookingsTab(context);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }).catchError((error) {
        print("DEBUG: ERROR creating booking: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $error')),
        );
      });
    } else {
      print("DEBUG: Negotiation was not accepted or was cancelled");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the registration date safely
    final createdAt = widget.worker['createdAt'];
    final registrationDate =
        (createdAt is Timestamp) ? createdAt.toDate() : DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy').format(registrationDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker['name'] ?? 'Worker Profile'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Worker Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.location_on, 'Location',
                        widget.worker['location'] ?? 'Not specified'),
                    const Divider(height: 18),
                    _buildDetailRow(Icons.calendar_today, 'Registered Since',
                        formattedDate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reviews section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadReviews,
                  icon: const Icon(Icons.refresh),
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
                  )
                : _reviews.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.star_border,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Be the first to review this worker',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ..._reviews
                              .map((review) => _buildReviewCard(review))
                              .toList(),
                          if (_reviews.length >= 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton.icon(
                                icon: const Icon(Icons.more_horiz),
                                label: const Text('View All Reviews'),
                                onPressed: () {
                                  // Could navigate to a full reviews page in the future
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Viewing all reviews will be available soon'),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
              const SizedBox(height: 2),
            Text(
              value,
                softWrap: true,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final reviewDate = review['date'] as DateTime;
    final formattedDate = DateFormat('MMM d, yyyy').format(reviewDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review['customerName'] ?? 'Anonymous',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildRatingStars(review['rating']),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review['comment'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }
}
