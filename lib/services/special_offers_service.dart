import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_offer.dart';

class SpecialOffersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache the offers
  List<SpecialOffer>? _cachedOffers;
  DateTime? _lastFetchTime;

  Future<List<SpecialOffer>> getSpecialOffers() async {
    // If we have a recent cache (less than 10 minutes old), use it
    if (_cachedOffers != null && _lastFetchTime != null) {
      final cacheAge = DateTime.now().difference(_lastFetchTime!);
      if (cacheAge.inMinutes < 10) {
        return _cachedOffers!;
      }
    }

    try {
      final querySnapshot = await _firestore
          .collection('special_offers')
          .where('isActive', isEqualTo: true)
          .get();

      final offers = querySnapshot.docs
          .map((doc) => SpecialOffer.fromMap(doc.data(), doc.id))
          .toList();

      // Update cache
      _cachedOffers = offers;
      _lastFetchTime = DateTime.now();

      return offers;
    } catch (e) {
      print('Error fetching special offers: $e');
      // Return cached offers if available, otherwise empty list
      return _cachedOffers ?? [];
    }
  }

  Stream<List<SpecialOffer>> specialOffersStream() {
    return _firestore
        .collection('special_offers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => SpecialOffer.fromMap(doc.data(), doc.id))
          .toList();

      // Update cache on new data
      _cachedOffers = offers;
      _lastFetchTime = DateTime.now();

      return offers;
    });
  }

  // Clear the cache to force a refresh
  void clearCache() {
    _cachedOffers = null;
    _lastFetchTime = null;
  }

  // Utility method to add a sample offer (only for development)
  Future<void> addSpecialOffer(Map<String, dynamic> offerData) async {
    try {
      // Ensure required timestamp fields exist
      final now = Timestamp.now();
      if (!offerData.containsKey('created_at')) {
        offerData['created_at'] = now;
      }
      if (!offerData.containsKey('updated_at')) {
        offerData['updated_at'] = now;
      }
      if (!offerData.containsKey('validUntil')) {
        // Default to 30 days in the future
        offerData['validUntil'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        );
      }

      await _firestore.collection('special_offers').add(offerData);

      // Clear cache after adding a new offer
      clearCache();
    } catch (e) {
      print('Error adding special offer: $e');
      rethrow;
    }
  }
}
