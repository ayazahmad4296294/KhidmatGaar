import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_package.dart';

class PackageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new package
  Future<String> createPackage(ServicePackage package) async {
    try {
      final docRef =
          await _firestore.collection('packages').add(package.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating package: $e');
      rethrow;
    }
  }

  // Get all pre-built packages
  Future<List<PreBuiltPackage>> getPreBuiltPackages() async {
    try {
      final snapshot = await _firestore.collection('prebuilt_packages').get();
      return snapshot.docs
          .map((doc) => PreBuiltPackage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting pre-built packages: $e');
      rethrow;
    }
  }

  // Get a specific pre-built package by ID
  Future<PreBuiltPackage?> getPreBuiltPackageById(String packageId) async {
    try {
      final doc =
          await _firestore.collection('prebuilt_packages').doc(packageId).get();
      if (doc.exists) {
        return PreBuiltPackage.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting pre-built package: $e');
      rethrow;
    }
  }

  // Create a package from a pre-built package template
  Future<String> createPackageFromPreBuilt(String preBuiltPackageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the pre-built package
      final preBuiltPackage = await getPreBuiltPackageById(preBuiltPackageId);
      if (preBuiltPackage == null) {
        throw Exception('Pre-built package not found');
      }

      // Get workers for each service in the pre-built package
      List<ServicePackageItem> packageItems = [];

      for (String serviceName in preBuiltPackage.includedServices) {
        // Find a worker for this service
        final workersQuery = await _firestore
            .collection('workers')
            .where('service', isEqualTo: serviceName)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();

        if (workersQuery.docs.isNotEmpty) {
          final workerDoc = workersQuery.docs.first;
          final workerData = workerDoc.data();

          // Add the service with an assigned worker
          packageItems.add(ServicePackageItem(
            serviceId: serviceName.toLowerCase(),
            serviceName: serviceName,
            price: _getServicePrice(serviceName),
            workerId: workerDoc.id,
            workerName:
                '${workerData['firstName'] ?? ''} ${workerData['lastName'] ?? ''}',
          ));
        }
      }

      // Calculate pricing
      double totalBeforeDiscount =
          packageItems.fold(0.0, (double sum, item) => sum + item.price) *
              preBuiltPackage.durationMonths;
      double totalAfterDiscount =
          totalBeforeDiscount * (1 - preBuiltPackage.discount / 100);

      // Create the package
      final package = ServicePackage(
        userId: user.uid,
        items: packageItems,
        durationMonths: preBuiltPackage.durationMonths,
        totalBeforeDiscount: totalBeforeDiscount,
        totalAfterDiscount: totalAfterDiscount,
        createdAt: DateTime.now(),
        packageType: 'pre-built',
        preBuiltPackageId: preBuiltPackageId,
      );

      return createPackage(package);
    } catch (e) {
      print('Error creating package from pre-built: $e');
      rethrow;
    }
  }

  // Helper method to get price for a service
  double _getServicePrice(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'maid':
        return 2500.0;
      case 'cook':
        return 3000.0;
      case 'driver':
        return 2800.0;
      case 'security guard':
        return 3500.0;
      case 'baby care taker':
        return 4000.0;
      case 'gardener':
        return 2200.0;
      case 'handyman':
        return 3200.0;
      case 'locksmith':
        return 4500.0;
      case 'auto mechanic':
        return 3800.0;
      case 'chef':
        return 5000.0;
      default:
        return 3000.0;
    }
  }

  // Get all packages for the current user
  Stream<List<ServicePackage>> getUserPackages() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('packages')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServicePackage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get a specific package by ID
  Future<ServicePackage?> getPackageById(String packageId) async {
    try {
      final doc = await _firestore.collection('packages').doc(packageId).get();
      if (doc.exists) {
        return ServicePackage.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting package: $e');
      rethrow;
    }
  }

  // Update package status
  Future<void> updatePackageStatus(String packageId, String status) async {
    try {
      await _firestore.collection('packages').doc(packageId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating package status: $e');
      rethrow;
    }
  }

  // Cancel a package
  Future<void> cancelPackage(String packageId) async {
    return updatePackageStatus(packageId, 'cancelled');
  }

  // Calculate total package price before discount
  double calculateTotalBeforeDiscount(
      List<ServicePackageItem> items, int durationMonths) {
    // Sum all service prices and multiply by the number of months
    double total = items.fold(0.0, (double sum, item) => sum + item.price);
    return total * durationMonths;
  }

  // Calculate final package price after applying discounts
  double calculateFinalPrice(
      List<ServicePackageItem> items, int durationMonths) {
    double totalBeforeDiscount =
        calculateTotalBeforeDiscount(items, durationMonths);
    return ServicePackage.calculateDiscountedTotal(
        totalBeforeDiscount, durationMonths);
  }
}
