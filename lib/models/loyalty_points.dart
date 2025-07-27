import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransaction {
  final String id;
  final String userId;
  final int points;
  final String type; // 'earned', 'redeemed', 'expired', 'bonus'
  final String description;
  final String? source; // 'booking', 'referral', 'package', 'promotion'
  final String? referenceId; // ID of the related booking/referral/etc
  final DateTime date;
  final DateTime? expiryDate;

  PointTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    this.source,
    this.referenceId,
    required this.date,
    this.expiryDate,
  });

  factory PointTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return PointTransaction(
      id: docId,
      userId: map['userId'] ?? '',
      points: map['points'] ?? 0,
      type: map['type'] ?? 'earned',
      description: map['description'] ?? '',
      source: map['source'],
      referenceId: map['referenceId'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'points': points,
      'type': type,
      'description': description,
      'source': source,
      'referenceId': referenceId,
      'date': Timestamp.fromDate(date),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }
}

class LoyaltyPointsSummary {
  final String userId;
  final int totalEarned;
  final int totalRedeemed;
  final int totalExpired;
  final int availablePoints;

  LoyaltyPointsSummary({
    required this.userId,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.totalExpired,
    required this.availablePoints,
  });

  factory LoyaltyPointsSummary.fromMap(Map<String, dynamic> map) {
    return LoyaltyPointsSummary(
      userId: map['userId'] ?? '',
      totalEarned: map['totalEarned'] ?? 0,
      totalRedeemed: map['totalRedeemed'] ?? 0,
      totalExpired: map['totalExpired'] ?? 0,
      availablePoints: map['availablePoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'totalExpired': totalExpired,
      'availablePoints': availablePoints,
    };
  }
}
