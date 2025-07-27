import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialOffer {
  final String id;
  final String title;
  final int discount;
  final String description;
  final String imageUrl;
  final bool isActive;
  final String code;
  final DateTime validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpecialOffer({
    required this.id,
    required this.title,
    required this.discount,
    required this.description,
    this.imageUrl = '',
    this.isActive = true,
    required this.code,
    required this.validUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpecialOffer.fromMap(Map<String, dynamic> data, String id) {
    return SpecialOffer(
      id: id,
      title: data['title'] ?? '',
      discount: data['discount'] ?? 0,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      code: data['code'] ?? '',
      validUntil:
          (data['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'discount': discount,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'code': code,
      'validUntil': Timestamp.fromDate(validUntil),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
