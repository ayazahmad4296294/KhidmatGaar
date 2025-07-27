import 'package:cloud_firestore/cloud_firestore.dart';

class ServicePackageItem {
  final String serviceId;
  final String serviceName;
  final double price;
  final String workerId;
  final String workerName;

  ServicePackageItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.workerId,
    required this.workerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'workerId': workerId,
      'workerName': workerName,
    };
  }

  factory ServicePackageItem.fromMap(Map<String, dynamic> map) {
    return ServicePackageItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
    );
  }
}

class PreBuiltPackage {
  final String id;
  final String name;
  final String description;
  final List<String> includedServices;
  final double price;
  final int durationMonths;
  final double discount;
  final String imageUrl;

  PreBuiltPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.includedServices,
    required this.price,
    required this.durationMonths,
    required this.discount,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'includedServices': includedServices,
      'price': price,
      'durationMonths': durationMonths,
      'discount': discount,
      'imageUrl': imageUrl,
    };
  }

  factory PreBuiltPackage.fromMap(Map<String, dynamic> map, [String? docId]) {
    return PreBuiltPackage(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      includedServices: List<String>.from(map['includedServices'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      durationMonths: map['durationMonths'] ?? 1,
      discount: (map['discount'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class ServicePackage {
  final String? id;
  final String userId;
  final List<ServicePackageItem> items;
  final int durationMonths; // 1, 2, or 3 months
  final double totalBeforeDiscount;
  final double totalAfterDiscount;
  final DateTime createdAt;
  final String status; // pending, active, completed, cancelled
  final String packageType; // 'custom' or 'pre-built'
  final String?
      preBuiltPackageId; // Reference to pre-built package if applicable

  ServicePackage({
    this.id,
    required this.userId,
    required this.items,
    required this.durationMonths,
    required this.totalBeforeDiscount,
    required this.totalAfterDiscount,
    required this.createdAt,
    this.status = 'pending',
    this.packageType = 'custom',
    this.preBuiltPackageId,
  });

  // Calculate discount percentage based on duration
  static double getDiscountPercentage(int durationMonths) {
    switch (durationMonths) {
      case 1:
        return 3.0; // 3% discount
      case 2:
        return 5.0; // 5% discount
      case 3:
        return 7.0; // 7% discount
      default:
        return 0.0;
    }
  }

  // Calculate total after discount
  static double calculateDiscountedTotal(
      double totalBeforeDiscount, int durationMonths) {
    double discountPercentage = getDiscountPercentage(durationMonths);
    double discountAmount = totalBeforeDiscount * (discountPercentage / 100);
    return totalBeforeDiscount - discountAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'durationMonths': durationMonths,
      'totalBeforeDiscount': totalBeforeDiscount,
      'totalAfterDiscount': totalAfterDiscount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'packageType': packageType,
      'preBuiltPackageId': preBuiltPackageId,
    };
  }

  factory ServicePackage.fromMap(Map<String, dynamic> map, String docId) {
    return ServicePackage(
      id: docId,
      userId: map['userId'] ?? '',
      items: List<ServicePackageItem>.from(
        (map['items'] ?? []).map(
          (item) => ServicePackageItem.fromMap(item),
        ),
      ),
      durationMonths: map['durationMonths'] ?? 1,
      totalBeforeDiscount: (map['totalBeforeDiscount'] ?? 0.0).toDouble(),
      totalAfterDiscount: (map['totalAfterDiscount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      packageType: map['packageType'] ?? 'custom',
      preBuiltPackageId: map['preBuiltPackageId'],
    );
  }
}
