import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;

enum BookingStatus { pending, accepted, ongoing, completed, cancelled }

enum BookingType { onDemand, monthly }

class BookingModel {
  final String id;
  final String userId;
  final String providerId;
  final String serviceType;
  final DateTime bookingDate;
  final TimeOfDay startTime;
  final BookingType bookingType;
  final BookingStatus status;
  final double amount;
  final String location;
  final String? notes;

  BookingModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceType,
    required this.bookingDate,
    required this.startTime,
    required this.bookingType,
    this.status = BookingStatus.pending,
    required this.amount,
    required this.location,
    this.notes,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      providerId: map['providerId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      startTime:
          TimeOfDay.fromDateTime((map['startTime'] as Timestamp).toDate()),
      bookingType: BookingType.values.firstWhere(
        (e) => e.toString() == map['bookingType'],
        orElse: () => BookingType.onDemand,
      ),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'serviceType': serviceType,
      'bookingDate': bookingDate,
      'startTime': startTime,
      'bookingType': bookingType.toString(),
      'status': status.toString(),
      'amount': amount,
      'location': location,
      'notes': notes,
    };
  }
}
