import 'package:cloud_firestore/cloud_firestore.dart';

/// This class is only for development purposes
/// It allows populating the database with sample special offers data
class SampleDataUtil {
  static Future<void> addSampleSpecialOffers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final now = DateTime.now();
    final futureDate =
        DateTime(now.year, now.month + 1, now.day); // One month from now

    // Sample special offers data matching Firebase structure
    final offers = [
      {
        'title': 'Security Guard',
        'discount': 20,
        'description':
            'If you book 2 security guards we will give you discount',
        'imageUrl': '',
        'isActive': true,
        'code': 'SECURE20',
        'validUntil': Timestamp.fromDate(futureDate),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      },
      {
        'title': 'Maid Service',
        'discount': 15,
        'description': 'First booking discount for all new customers',
        'imageUrl': '',
        'isActive': true,
        'code': 'MAID15',
        'validUntil': Timestamp.fromDate(futureDate),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      },
      {
        'title': 'Driver',
        'discount': 25,
        'description': 'Special discount on monthly subscription packages',
        'imageUrl': '',
        'isActive': true,
        'code': 'DRIVE25',
        'validUntil': Timestamp.fromDate(futureDate),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      },
      {
        'title': 'Chef',
        'discount': 10,
        'description': 'Weekend booking special offer',
        'imageUrl': '',
        'isActive': true,
        'code': 'CHEF10',
        'validUntil': Timestamp.fromDate(futureDate),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      },
      {
        'title': 'Handyman',
        'discount': 30,
        'description': 'Limited time offer for household repairs',
        'imageUrl': '',
        'isActive': true,
        'code': 'HANDY30',
        'validUntil': Timestamp.fromDate(futureDate),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      },
    ];

    // Add each offer to the batch
    for (final offer in offers) {
      final docRef = firestore.collection('special_offers').doc();
      batch.set(docRef, offer);
    }

    // Commit the batch
    return batch.commit();
  }
}
