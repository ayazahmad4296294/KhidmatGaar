import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String workerId;
  final String customerId;
  final String customerName;
  final String bookingId;
  final String serviceType;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.workerId,
    required this.customerId,
    required this.customerName,
    required this.bookingId,
    required this.serviceType,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      workerId: map['workerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Customer',
      bookingId: map['bookingId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'customerId': customerId,
      'customerName': customerName,
      'bookingId': bookingId,
      'serviceType': serviceType,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
