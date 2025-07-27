import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/loyalty_points.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points earning constants
  static const int POINTS_PER_BOOKING = 100;
  static const int POINTS_PER_PACKAGE = 150;
  static const int POINTS_PER_REFERRAL = 200;
  static const int POINTS_THRESHOLD_BONUS =
      1000; // Points for high-value bookings

  // Get user's current loyalty points summary
  Future<LoyaltyPointsSummary> getUserPointsSummary() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore
        .collection('loyalty_points_summary')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // Create an empty summary if none exists
      final newSummary = LoyaltyPointsSummary(
        userId: user.uid,
        totalEarned: 0,
        totalRedeemed: 0,
        totalExpired: 0,
        availablePoints: 0,
      );

      await _firestore
          .collection('loyalty_points_summary')
          .doc(user.uid)
          .set(newSummary.toMap());

      return newSummary;
    }

    return LoyaltyPointsSummary.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Get user's point transactions
  Stream<List<PointTransaction>> getUserPointTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('loyalty_transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointTransaction.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Add points to user (for earning points)
  Future<void> addPoints({
    required int points,
    required String description,
    required String source,
    String? referenceId,
    bool isBonus = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Set expiry date (1 year from now)
    final expiryDate = DateTime.now().add(const Duration(days: 365));

    // Create transaction
    final transaction = PointTransaction(
      id: '', // Will be set by Firestore
      userId: user.uid,
      points: points,
      type: isBonus ? 'bonus' : 'earned',
      description: description,
      source: source,
      referenceId: referenceId,
      date: DateTime.now(),
      expiryDate: expiryDate,
    );

    // Add transaction to Firestore
    await _firestore
        .collection('loyalty_transactions')
        .add(transaction.toMap());

    // Update summary
    await _firestore.runTransaction((transaction) async {
      final summaryRef =
          _firestore.collection('loyalty_points_summary').doc(user.uid);
      final summaryDoc = await transaction.get(summaryRef);

      if (!summaryDoc.exists) {
        // Create new summary
        transaction.set(
            summaryRef,
            LoyaltyPointsSummary(
              userId: user.uid,
              totalEarned: points,
              totalRedeemed: 0,
              totalExpired: 0,
              availablePoints: points,
            ).toMap());
      } else {
        // Update existing summary
        final currentSummary = LoyaltyPointsSummary.fromMap(summaryDoc.data()!);
        transaction.update(summaryRef, {
          'totalEarned': currentSummary.totalEarned + points,
          'availablePoints': currentSummary.availablePoints + points,
        });
      }
    });
  }

  // Redeem points for discount
  Future<bool> redeemPoints({
    required int points,
    required String description,
    required String referenceId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Check if user has enough points
    final summary = await getUserPointsSummary();
    if (summary.availablePoints < points) {
      return false; // Not enough points
    }

    // Create redemption transaction
    final transaction = PointTransaction(
      id: '', // Will be set by Firestore
      userId: user.uid,
      points: points,
      type: 'redeemed',
      description: description,
      source: 'discount',
      referenceId: referenceId,
      date: DateTime.now(),
      expiryDate: null, // No expiry for redemptions
    );

    // Add transaction to Firestore
    await _firestore
        .collection('loyalty_transactions')
        .add(transaction.toMap());

    // Update summary
    await _firestore.runTransaction((transaction) async {
      final summaryRef =
          _firestore.collection('loyalty_points_summary').doc(user.uid);
      final summaryDoc = await transaction.get(summaryRef);

      if (summaryDoc.exists) {
        final currentSummary = LoyaltyPointsSummary.fromMap(summaryDoc.data()!);
        transaction.update(summaryRef, {
          'totalRedeemed': currentSummary.totalRedeemed + points,
          'availablePoints': currentSummary.availablePoints - points,
        });
      }
    });

    return true; // Redemption successful
  }

  // Calculate points to be awarded for a booking
  int calculateBookingPoints(double bookingValue) {
    int points = POINTS_PER_BOOKING;

    // Add bonus points for high-value bookings
    if (bookingValue >= 5000) {
      points += POINTS_THRESHOLD_BONUS;
    }

    return points;
  }

  // Award points for a completed booking
  Future<void> awardBookingPoints(String bookingId, double bookingValue) async {
    int points = calculateBookingPoints(bookingValue);

    await addPoints(
      points: points,
      description: 'Points earned for completing a booking',
      source: 'booking',
      referenceId: bookingId,
    );
  }

  // Award points for a package purchase
  Future<void> awardPackagePoints(String packageId) async {
    await addPoints(
      points: POINTS_PER_PACKAGE,
      description: 'Points earned for purchasing a service package',
      source: 'package',
      referenceId: packageId,
    );
  }

  // Award points for a successful referral
  Future<void> awardReferralPoints(String referredUserId) async {
    await addPoints(
      points: POINTS_PER_REFERRAL,
      description: 'Points earned for referring a new user',
      source: 'referral',
      referenceId: referredUserId,
      isBonus: true,
    );
  }

  // Check for expired points and update
  Future<void> checkForExpiredPoints() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();

    // Get all non-expired, non-redeemed transactions
    final querySnapshot = await _firestore
        .collection('loyalty_transactions')
        .where('userId', isEqualTo: user.uid)
        .where('type', whereIn: ['earned', 'bonus'])
        .where('expiryDate', isLessThan: Timestamp.fromDate(now))
        .get();

    int totalExpiredPoints = 0;

    // Process expired transactions
    for (var doc in querySnapshot.docs) {
      final transaction =
          PointTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Create expiration transaction
      final expirationTransaction = PointTransaction(
        id: '',
        userId: user.uid,
        points: transaction.points,
        type: 'expired',
        description: 'Points expired from ${transaction.description}',
        source: transaction.source,
        referenceId: transaction.referenceId,
        date: now,
        expiryDate: null,
      );

      await _firestore
          .collection('loyalty_transactions')
          .add(expirationTransaction.toMap());

      totalExpiredPoints += transaction.points;
    }

    if (totalExpiredPoints > 0) {
      // Update summary with expired points
      await _firestore.runTransaction((transaction) async {
        final summaryRef =
            _firestore.collection('loyalty_points_summary').doc(user.uid);
        final summaryDoc = await transaction.get(summaryRef);

        if (summaryDoc.exists) {
          final currentSummary =
              LoyaltyPointsSummary.fromMap(summaryDoc.data()!);
          transaction.update(summaryRef, {
            'totalExpired': currentSummary.totalExpired + totalExpiredPoints,
            'availablePoints':
                currentSummary.availablePoints - totalExpiredPoints,
          });
        }
      });
    }
  }
}
