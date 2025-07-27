import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled
}

extension BookingStatusExtension on BookingStatus {
  String get name {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  Color getStatusColor() {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rescheduled:
        return Colors.amber;
    }
  }
}

class Booking {
  final String? id;
  final String userId;
  final String workerId;
  final String workerName;
  final String serviceType;
  final String address;
  final DateTime scheduledDateTime;
  final String status; // Using string to facilitate Firestore storage
  final double price;
  final double? discountAmount;
  final int? loyaltyPointsEarned;
  final int? loyaltyPointsRedeemed;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isPaid;
  final String paymentMethod; // 'cash', 'card', 'wallet'
  final bool isReviewed;

  Booking({
    this.id,
    required this.userId,
    required this.workerId,
    required this.workerName,
    required this.serviceType,
    required this.address,
    required this.scheduledDateTime,
    required this.status,
    required this.price,
    this.discountAmount,
    this.loyaltyPointsEarned,
    this.loyaltyPointsRedeemed,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.isPaid = false,
    this.paymentMethod = 'cash',
    this.isReviewed = false,
  });

  // Get the BookingStatus enum from the string status
  BookingStatus get statusEnum {
    return BookingStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => BookingStatus.pending,
    );
  }

  // Create a new instance with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? workerId,
    String? workerName,
    String? serviceType,
    String? address,
    DateTime? scheduledDateTime,
    String? status,
    double? price,
    double? discountAmount,
    int? loyaltyPointsEarned,
    int? loyaltyPointsRedeemed,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isPaid,
    String? paymentMethod,
    bool? isReviewed,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      serviceType: serviceType ?? this.serviceType,
      address: address ?? this.address,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      price: price ?? this.price,
      discountAmount: discountAmount ?? this.discountAmount,
      loyaltyPointsEarned: loyaltyPointsEarned ?? this.loyaltyPointsEarned,
      loyaltyPointsRedeemed:
          loyaltyPointsRedeemed ?? this.loyaltyPointsRedeemed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  // Convert booking to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workerId': workerId,
      'workerName': workerName,
      'serviceType': serviceType,
      'address': address,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'status': status,
      'price': price,
      'discountAmount': discountAmount,
      'loyaltyPointsEarned': loyaltyPointsEarned,
      'loyaltyPointsRedeemed': loyaltyPointsRedeemed,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'isReviewed': isReviewed,
    };
  }

  // Create Booking from Firestore document
  factory Booking.fromMap(Map<String, dynamic> map, String docId) {
    return Booking(
      id: docId,
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      serviceType: map['serviceType'] ?? '',
      address: map['address'] ?? '',
      scheduledDateTime: (map['scheduledDateTime'] as Timestamp).toDate(),
      status: map['status'] ?? BookingStatus.pending.value,
      price: (map['price'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      loyaltyPointsEarned: map['loyaltyPointsEarned'],
      loyaltyPointsRedeemed: map['loyaltyPointsRedeemed'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'] ?? 'cash',
      isReviewed: map['isReviewed'] ?? false,
    );
  }
}
