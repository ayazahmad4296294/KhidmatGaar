import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final double loyaltyPoints;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.loyaltyPoints = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      loyaltyPoints: (map['loyaltyPoints'] ?? 0).toDouble(),
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'loyaltyPoints': loyaltyPoints,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }
}
