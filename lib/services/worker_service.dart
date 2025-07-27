import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update worker online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch current revenue
      final doc = await _firestore.collection('workers').doc(user.uid).get();
      double revenue = 0.0;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final revenueStr = data['revenue']?.toString() ?? '0';
        revenue = double.tryParse(revenueStr) ?? 0.0;
      }

      if (revenue < 200) {
        // Force offline if balance is insufficient
        await _firestore.collection('workers').doc(user.uid).update({
          'isOnline': false,
          'lastStatusChange': FieldValue.serverTimestamp(),
        });
        throw Exception(
            'Insufficient wallet balance. You need at least Rs 200 to go online.');
      }

      await _firestore.collection('workers').doc(user.uid).update({
        'isOnline': isOnline,
        'lastStatusChange': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating worker online status: $e');
      throw e;
    }
  }

  // Get worker online status
  Future<bool> getOnlineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final workerDoc =
          await _firestore.collection('workers').doc(user.uid).get();
      if (workerDoc.exists) {
        final data = workerDoc.data();
        if (data != null) {
          return data['isOnline'] ?? false;
        }
      }
      return false;
    } catch (e) {
      print('Error getting worker online status: $e');
      return false;
    }
  }

  // Get all active workers for a service
  Future<List<Map<String, dynamic>>> getActiveWorkersForService(
      String serviceName) async {
    try {
      final lowerCaseServiceName = serviceName.toLowerCase();

      // Query workers that are online, provide the selected service, and have approved status
      QuerySnapshot workersQuery = await _firestore
          .collection('workers')
          .where('service', whereIn: [serviceName, lowerCaseServiceName])
          .where('status', isEqualTo: 'approved')
          .where('isOnline', isEqualTo: true)
          .get();

      final workers = workersQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();

        return {
          'id': doc.id,
          'name': fullName.isNotEmpty
              ? fullName
              : 'Worker ${doc.id.substring(0, 4)}',
          'experience': data['expirence']?.toString() ??
              data['experience']?.toString() ??
              'Not specified',
          'location': data['location']?.toString() ?? 'Not specified',
          'service': data['service']?.toString() ?? '',
          'isOnline': data['isOnline'] ?? false,
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'completedJobs': (data['completedJobs'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      return workers;
    } catch (e) {
      print('Error loading active workers: $e');
      return [];
    }
  }

  // Increment worker's completed jobs count
  Future<void> incrementCompletedJobs(String workerId) async {
    try {
      print(
          'DEBUG: WorkerService - Incrementing completed jobs for worker: $workerId');

      // Get the current count
      final workerDoc =
          await _firestore.collection('workers').doc(workerId).get();
      if (!workerDoc.exists) {
        print('DEBUG: WorkerService - Worker document not found: $workerId');
        throw Exception('Worker not found');
      }

      final workerData = workerDoc.data()!;
      final int currentCompletedJobs =
          (workerData['completedJobs'] as num?)?.toInt() ?? 0;
      final int newCompletedJobs = currentCompletedJobs + 1;

      print(
          'DEBUG: WorkerService - Current completed jobs: $currentCompletedJobs, updating to: $newCompletedJobs');

      // Update the count
      await _firestore.collection('workers').doc(workerId).update({
        'completedJobs': newCompletedJobs,
      });

      print('DEBUG: WorkerService - Successfully updated completed jobs count');

      // Verify the update
      final updatedDoc =
          await _firestore.collection('workers').doc(workerId).get();
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data()!;
        final updatedCount =
            (updatedData['completedJobs'] as num?)?.toInt() ?? 0;
        print('DEBUG: WorkerService - Verified updated count: $updatedCount');
      }
    } catch (e) {
      print('ERROR: WorkerService - Failed to increment completed jobs: $e');
      throw e;
    }
  }

  // Get worker's completed jobs count
  Future<int> getCompletedJobsCount(String workerId) async {
    try {
      print(
          'DEBUG: WorkerService - Getting completed jobs count for worker: $workerId');

      final workerDoc =
          await _firestore.collection('workers').doc(workerId).get();
      if (!workerDoc.exists) {
        print('DEBUG: WorkerService - Worker document not found: $workerId');
        return 0;
      }

      final workerData = workerDoc.data()!;
      final int completedJobs =
          (workerData['completedJobs'] as num?)?.toInt() ?? 0;

      print(
          'DEBUG: WorkerService - Current completed jobs count: $completedJobs');
      return completedJobs;
    } catch (e) {
      print('ERROR: WorkerService - Failed to get completed jobs count: $e');
      return 0;
    }
  }
}
