import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get reviews => _firestore.collection('reviews');
  CollectionReference get workers => _firestore.collection('workers');

  // Submit a new review
  Future<void> submitReview({
    required String workerId,
    required String bookingId,
    required String serviceType,
    required double rating,
    required String comment,
    required String customerName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Create review data
    final reviewData = {
      'workerId': workerId,
      'customerId': currentUser.uid,
      'customerName': customerName,
      'bookingId': bookingId,
      'serviceType': serviceType,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add review to Firestore
    await reviews.add(reviewData);

    // Update worker's average rating
    await _updateWorkerRating(workerId);

    // Update booking to mark as reviewed
    await _firestore.collection('bookings').doc(bookingId).update({
      'isReviewed': true,
    });
  }

  // Get reviews for a worker
  Future<List<Review>> getWorkerReviews(String workerId) async {
    final querySnapshot = await reviews
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map(
            (doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Check if a booking has been reviewed
  Future<bool> isBookingReviewed(String bookingId) async {
    final querySnapshot =
        await reviews.where('bookingId', isEqualTo: bookingId).limit(1).get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Update worker's average rating
  Future<void> _updateWorkerRating(String workerId) async {
    try {
      // Get all reviews for this worker
      final querySnapshot =
          await reviews.where('workerId', isEqualTo: workerId).get();

      if (querySnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      int count = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('rating')) {
          totalRating += (data['rating'] as num).toDouble();
          count++;
        }
      }

      double averageRating = count > 0 ? totalRating / count : 0;

      // Update worker document with new rating and completed jobs count
      await workers.doc(workerId).update({
        'rating': averageRating,
        'reviewCount': count,
      });
    } catch (e) {
      print('Error updating worker rating: $e');
    }
  }
}
