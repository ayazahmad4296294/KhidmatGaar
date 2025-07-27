import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import 'loyalty_service.dart';
import 'notification_service.dart';
import 'worker_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoyaltyService _loyaltyService = LoyaltyService();
  final NotificationService _notificationService = NotificationService();
  final WorkerService _workerService = WorkerService();

  // Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      print("DEBUG: BookingService - Creating new booking in Firestore");
      print("DEBUG: BookingService - Booking data: ${booking.toMap()}");

      final docRef =
          await _firestore.collection('bookings').add(booking.toMap());

      print("DEBUG: BookingService - Booking created with ID: ${docRef.id}");

      // Send notification to customer
      await _notificationService.sendBookingConfirmationNotification(
        userId: booking.userId,
        bookingId: docRef.id,
        serviceType: booking.serviceType,
        bookingTime: booking.scheduledDateTime,
      );

      // Send notification to worker
      await _notificationService.sendWorkerBookingAlert(
        workerId: booking.workerId,
        bookingId: docRef.id,
        customerName: await _getUserName(booking.userId),
        serviceType: booking.serviceType,
        bookingTime: booking.scheduledDateTime,
      );

      return docRef.id;
    } catch (e) {
      print('ERROR creating booking: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      rethrow;
    }
  }

  // Get all bookings for the current user
  Stream<List<Booking>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all bookings for a worker
  Stream<List<Booking>> getWorkerBookings(String workerId) {
    return _firestore
        .collection('bookings')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update booking status
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.value,
      });

      // If the booking is completed, award loyalty points
      if (status == BookingStatus.completed) {
        await _awardLoyaltyPointsForCompletedBooking(bookingId);
      }

      // Get booking details for notifications
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        // Send notification to customer about status update
        await _notificationService.sendBookingUpdateNotification(
          userId: booking.userId,
          bookingId: bookingId,
          serviceType: booking.serviceType,
          status: status.value,
        );
      }
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get booking details for notifications before updating status
      final booking = await getBookingById(bookingId);

      await updateBookingStatus(bookingId, BookingStatus.cancelled);

      // Send cancellation notification
      if (booking != null) {
        await _notificationService.sendBookingCancellationNotification(
          userId: booking.userId,
          bookingId: bookingId,
          serviceType: booking.serviceType,
        );
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  // Update booking with loyalty points redeem
  Future<void> applyLoyaltyPointsDiscount(
      String bookingId, int pointsToRedeem) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    // Calculate discount amount (500 points = PKR 100)
    final discountAmount = (pointsToRedeem / 500) * 100;

    try {
      // Redeem points first to ensure user has enough points
      final success = await _loyaltyService.redeemPoints(
        points: pointsToRedeem,
        description: 'Points redeemed for booking discount',
        referenceId: bookingId,
      );

      if (!success) {
        throw Exception('Failed to redeem points');
      }

      // Update booking with discount and redeemed points
      await _firestore.collection('bookings').doc(bookingId).update({
        'discountAmount': discountAmount,
        'loyaltyPointsRedeemed': pointsToRedeem,
        'price': booking.price - discountAmount,
      });
    } catch (e) {
      print('Error applying loyalty points discount: $e');
      rethrow;
    }
  }

  // Complete the booking and award loyalty points
  Future<void> completeBooking(String bookingId) async {
    try {
      // Get the booking to find the workerId
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final String workerId = bookingData['workerId'] ?? '';

      print('DEBUG: CompleteBooking - Found booking with workerId: $workerId');

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('DEBUG: CompleteBooking - Updated booking status to completed');

      // Increment worker's completed jobs count using the WorkerService
      if (workerId.isNotEmpty) {
        print(
            'DEBUG: CompleteBooking - Calling WorkerService to increment completed jobs');
        await _workerService.incrementCompletedJobs(workerId);
      } else {
        print('DEBUG: CompleteBooking - No workerId found in booking');
      }

      await _awardLoyaltyPointsForCompletedBooking(bookingId);
    } catch (e) {
      print('Error completing booking: $e');
      rethrow;
    }
  }

  // Helper method to award loyalty points for completed booking
  Future<void> _awardLoyaltyPointsForCompletedBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        return;
      }

      // Calculate and award loyalty points
      final int pointsToAward =
          _loyaltyService.calculateBookingPoints(booking.price);

      // Award points only if not already awarded
      if (booking.loyaltyPointsEarned == null ||
          booking.loyaltyPointsEarned == 0) {
        await _loyaltyService.awardBookingPoints(bookingId, booking.price);

        // Update booking with earned points
        await _firestore.collection('bookings').doc(bookingId).update({
          'loyaltyPointsEarned': pointsToAward,
        });
      }
    } catch (e) {
      print('Error awarding loyalty points: $e');
      // Don't rethrow here to prevent blocking booking completion
    }
  }

  // Create a booking with schedule
  Future<String> scheduleBooking({
    required String workerId,
    required String workerName,
    required String serviceType,
    required String address,
    required DateTime scheduledDateTime,
    required double price,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG: BookingService - User not authenticated");
      throw Exception('User not authenticated');
    }

    print("DEBUG: BookingService - Scheduling booking for user: ${user.uid}");
    print("DEBUG: BookingService - Worker ID: $workerId");
    print("DEBUG: BookingService - Service Type: $serviceType");
    print("DEBUG: BookingService - Scheduled for: $scheduledDateTime");

    final booking = Booking(
      userId: user.uid,
      workerId: workerId,
      workerName: workerName,
      serviceType: serviceType,
      address: address,
      scheduledDateTime: scheduledDateTime,
      status: BookingStatus.pending.value,
      price: price,
      createdAt: DateTime.now(),
      notes: notes,
    );

    print(
        "DEBUG: BookingService - Booking object created, status: ${booking.status}");

    return await createBooking(booking);
  }

  // Reschedule a booking
  Future<void> rescheduleBooking(
      String bookingId, DateTime newScheduledDateTime) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'scheduledDateTime': Timestamp.fromDate(newScheduledDateTime),
        'status': BookingStatus.rescheduled.value,
      });
    } catch (e) {
      print('Error rescheduling booking: $e');
      rethrow;
    }
  }

  // Mark booking as paid
  Future<void> markBookingAsPaid(String bookingId, String paymentMethod) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'isPaid': true,
        'paymentMethod': paymentMethod,
      });
    } catch (e) {
      print('Error marking booking as paid: $e');
      rethrow;
    }
  }

  // Add review status
  Future<void> markBookingAsReviewed(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'isReviewed': true,
      });
    } catch (e) {
      print('Error marking booking as reviewed: $e');
      rethrow;
    }
  }

  // Get upcoming bookings for the current user
  Stream<List<Booking>> getUpcomingBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG: getUpcomingBookings - User not authenticated");
      throw Exception('User not authenticated');
    }

    print(
        "DEBUG: getUpcomingBookings - Fetching upcoming bookings for user: ${user.uid}");
    print(
        "DEBUG: getUpcomingBookings - Filtering by statuses: [${BookingStatus.pending.value}, ${BookingStatus.confirmed.value}, ${BookingStatus.rescheduled.value}]");

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: [
          BookingStatus.pending.value,
          BookingStatus.confirmed.value,
          BookingStatus.rescheduled.value
        ])
        .orderBy('scheduledDateTime')
        .snapshots()
        .map((snapshot) {
          print(
              "DEBUG: getUpcomingBookings - Received snapshot with ${snapshot.docs.length} documents");

          final bookings = snapshot.docs
              .map((doc) {
                print("DEBUG: getUpcomingBookings - Processing doc: ${doc.id}");
                try {
                  return Booking.fromMap(doc.data(), doc.id);
                } catch (e) {
                  print(
                      "DEBUG: getUpcomingBookings - Error parsing doc ${doc.id}: $e");
                  print("DEBUG: getUpcomingBookings - Doc data: ${doc.data()}");
                  // Return null for failed parsing
                  return null;
                }
              })
              .where((booking) => booking != null) // Filter out nulls
              .cast<Booking>() // Cast to non-nullable
              .toList();

          print(
              "DEBUG: getUpcomingBookings - Successfully parsed ${bookings.length} bookings");
          return bookings;
        });
  }

  // Get completed bookings for the current user
  Stream<List<Booking>> getCompletedBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: BookingStatus.completed.value)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Helper method to get user name
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          return '$firstName $lastName'.trim();
        }
      }
      return 'Customer';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Customer';
    }
  }
}
