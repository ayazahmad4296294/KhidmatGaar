import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/negotiation.dart';

class NegotiationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get negotiations => _firestore.collection('negotiations');
  CollectionReference get marketRates => _firestore.collection('market_rates');

  // Create a new negotiation
  Future<String> startNegotiation({
    required String bookingId,
    required String workerId,
    required String serviceName,
    required double initialPrice,
    required double minAcceptablePrice,
    required double maxAcceptablePrice,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();

    final negotiationData = {
      'bookingId': bookingId,
      'workerId': workerId,
      'customerId': currentUser.uid,
      'serviceName': serviceName,
      'initialPrice': initialPrice,
      'minAcceptablePrice': minAcceptablePrice,
      'maxAcceptablePrice': maxAcceptablePrice,
      'currentOffer': initialPrice,
      'offerBy': 'worker', // Initial offer is from worker
      'isAccepted': false,
      'isRejected': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'offerHistory': [
        {
          'amount': initialPrice,
          'by': 'worker',
          'timestamp': Timestamp.fromDate(now),
          'message': 'Initial offer',
        }
      ],
    };

    final docRef = await negotiations.add(negotiationData);
    return docRef.id;
  }

  // Get negotiation by ID
  Future<PriceNegotiation?> getNegotiationById(String negotiationId) async {
    final docSnapshot = await negotiations.doc(negotiationId).get();

    if (!docSnapshot.exists) {
      return null;
    }

    return PriceNegotiation.fromMap(
      docSnapshot.data() as Map<String, dynamic>,
      docSnapshot.id,
    );
  }

  // Get all active negotiations for a customer
  Future<List<PriceNegotiation>> getCustomerNegotiations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final querySnapshot = await negotiations
        .where('customerId', isEqualTo: currentUser.uid)
        .where('isAccepted', isEqualTo: false)
        .where('isRejected', isEqualTo: false)
        .get();

    return querySnapshot.docs.map((doc) {
      return PriceNegotiation.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Get all active negotiations for a worker
  Future<List<PriceNegotiation>> getWorkerNegotiations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final querySnapshot = await negotiations
        .where('workerId', isEqualTo: currentUser.uid)
        .where('isAccepted', isEqualTo: false)
        .where('isRejected', isEqualTo: false)
        .get();

    return querySnapshot.docs.map((doc) {
      return PriceNegotiation.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Make a counter offer
  Future<void> makeCounterOffer({
    required String negotiationId,
    required double amount,
    String? message,
    required String by, // 'worker' or 'customer'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check if negotiation exists and is still active
    final negotiation = await getNegotiationById(negotiationId);
    if (negotiation == null) {
      throw Exception('Negotiation not found');
    }

    if (negotiation.isAccepted || negotiation.isRejected) {
      throw Exception('Negotiation is already closed');
    }

    // Validate the offer based on limits
    if (by == 'customer' && amount > negotiation.maxAcceptablePrice) {
      throw Exception('Offer exceeds your maximum acceptable price');
    }

    if (by == 'worker' && amount < negotiation.minAcceptablePrice) {
      throw Exception('Offer is below your minimum acceptable price');
    }

    // Create the new offer
    final now = DateTime.now();
    final newOffer = {
      'amount': amount,
      'by': by,
      'timestamp': Timestamp.fromDate(now),
      'message': message,
    };

    // Update the negotiation
    await negotiations.doc(negotiationId).update({
      'currentOffer': amount,
      'offerBy': by,
      'updatedAt': Timestamp.fromDate(now),
      'offerHistory': FieldValue.arrayUnion([newOffer]),
    });
  }

  // Accept current offer
  Future<void> acceptOffer(String negotiationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    await negotiations.doc(negotiationId).update({
      'isAccepted': true,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // Reject current offer
  Future<void> rejectOffer(String negotiationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    await negotiations.doc(negotiationId).update({
      'isRejected': true,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // Get suggested price range for a service
  Future<Map<String, dynamic>> getSuggestedPriceRange(
      String serviceName) async {
    final querySnapshot = await marketRates
        .where('serviceName', isEqualTo: serviceName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // Default fallback values if no market rate is found
      return {
        'minMarketRate': 0.0,
        'avgMarketRate': 0.0,
        'maxMarketRate': 0.0,
      };
    }

    final rateData = querySnapshot.docs.first.data() as Map<String, dynamic>;
    return {
      'minMarketRate': (rateData['minRate'] ?? 0.0).toDouble(),
      'avgMarketRate': (rateData['avgRate'] ?? 0.0).toDouble(),
      'maxMarketRate': (rateData['maxRate'] ?? 0.0).toDouble(),
    };
  }

  // Update or create market rates for a service
  Future<void> updateMarketRates({
    required String serviceName,
    required double minRate,
    required double avgRate,
    required double maxRate,
  }) async {
    final querySnapshot = await marketRates
        .where('serviceName', isEqualTo: serviceName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // Create new rate
      await marketRates.add({
        'serviceName': serviceName,
        'minRate': minRate,
        'avgRate': avgRate,
        'maxRate': maxRate,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      // Update existing rate
      final docId = querySnapshot.docs.first.id;
      await marketRates.doc(docId).update({
        'minRate': minRate,
        'avgRate': avgRate,
        'maxRate': maxRate,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Listen to changes in a negotiation
  Stream<PriceNegotiation> negotiationStream(String negotiationId) {
    return negotiations.doc(negotiationId).snapshots().map((snapshot) {
      return PriceNegotiation.fromMap(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
    });
  }
}
