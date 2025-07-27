import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ReviewScreen extends StatefulWidget {
  final Booking booking;
  final bool isReviewed;

  const ReviewScreen({
    Key? key,
    required this.booking,
    required this.isReviewed,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isSubmitting = false;
  double _rating = 0.0;
  Review? _existingReview;
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load customer name
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            setState(() {
              _customerName = userData['full_name'] ?? '';
            });
          }
        }
      }

      // If review exists, load it
      if (widget.isReviewed) {
        final querySnapshot = await _firestore
            .collection('reviews')
            .where('bookingId', isEqualTo: widget.booking.id)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final review =
              Review.fromMap(doc.data() as Map<String, dynamic>, doc.id);

          setState(() {
            _existingReview = review;
            _rating = review.rating;
            _commentController.text = review.comment;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a comment');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print(
          'DEBUG: Submitting review with comment: "${_commentController.text.trim()}"');
      print('DEBUG: Rating: $_rating');
      print('DEBUG: Worker ID: ${widget.booking.workerId}');
      print('DEBUG: Booking ID: ${widget.booking.id}');

      await _reviewService.submitReview(
        workerId: widget.booking.workerId,
        bookingId: widget.booking.id!,
        serviceType: widget.booking.serviceType,
        rating: _rating,
        comment: _commentController.text.trim(),
        customerName: _customerName,
      );

      print('DEBUG: Review submitted successfully!');

      // Return to previous screen with success flag
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('DEBUG: Error submitting review: $e');
      _showErrorSnackBar('Error submitting review: $e');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReviewed ? 'Your Review' : 'Write a Review'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service info
                          Text(
                            widget.booking.serviceType,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Provided by: ${widget.booking.workerName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${_formatDateTime(widget.booking.scheduledDateTime)}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Rating section
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: widget.isReviewed
                                ? null
                                : () {
                                    setState(() {
                                      _rating = index + 1;
                                    });
                                  },
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Comment section
                  const Text(
                    'Comment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    readOnly: widget.isReviewed,
                    decoration: InputDecoration(
                      hintText: 'Write your review here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor:
                          widget.isReviewed ? Colors.grey[100] : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  if (!widget.isReviewed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.purple,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                  // Review info
                  if (widget.isReviewed && _existingReview != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reviewed by: $_customerName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDate(_existingReview!.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
