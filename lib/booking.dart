import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String serviceName;
  final String serviceType;
  final String userId;
  String status;
  final String address;

  Booking({
    required this.id,
    required this.serviceName,
    required this.serviceType,
    required this.userId,
    required this.address,
    required this.status,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      serviceName: map['serviceName'] ?? '',
      serviceType: map['serviceType'] ?? '',
      userId: map['userId'] ?? '',
      address: map['address'] ?? '',
      status: map['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'serviceType': serviceType,
      'userId': userId,
      'address': address,
      'status': status,
    };
  }

  Future<void> updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({'status': newStatus});
      status = newStatus;
    } catch (e) {
      rethrow; // Propagate the error for handling in UI
    }
  }

  Future<void> delete() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
    } catch (e) {
      rethrow; // Propagate the error for handling in UI
    }
  }
}
