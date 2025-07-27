import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all services
  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('services').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Add a new service
  Future<void> addService(Map<String, dynamic> serviceData) async {
    try {
      await _firestore.collection('services').add(serviceData);
    } catch (e) {
      print('Error adding service: $e');
      throw e;
    }
  }

  // Update a service
  Future<void> updateService(
      String serviceId, Map<String, dynamic> serviceData) async {
    try {
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update(serviceData);
    } catch (e) {
      print('Error updating service: $e');
      throw e;
    }
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      print('Error deleting service: $e');
      throw e;
    }
  }

  // Get services with filters
  Future<List<Map<String, dynamic>>> getFilteredServices(
      Map<String, dynamic> filters) async {
    try {
      Query query = _firestore.collection('services');

      if (filters['service'] != null) {
        query = query.where('title', isEqualTo: filters['service']);
      }

      if (filters['location'] != null) {
        query = query.where('locations', arrayContains: filters['location']);
      }

      if (filters['rating'] != null && filters['rating'] > 0) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: filters['rating']);
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching filtered services: $e');
      return [];
    }
  }

  // Ensure chat collections are set up correctly
  Future<void> setupChatCollections() async {
    try {
      // Check if conversations collection exists by attempting to get a document
      final conversationsCheck =
          await _firestore.collection('conversations').limit(1).get();

      // If we don't have a messages subcollection, create a dummy doc to ensure structure exists
      if (conversationsCheck.docs.isEmpty) {
        print('Setting up conversations collection structure...');

        // Create a temporary document with a placeholder conversation
        final tempDocRef =
            _firestore.collection('conversations').doc('temp_setup_doc');

        // Add a basic structure
        await tempDocRef.set({
          'customerId': 'setup',
          'customerName': 'Setup User',
          'workerId': 'setup',
          'workerName': 'Setup Worker',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessage': 'Collection setup',
          'hasUnreadMessages': false,
          'setupDoc': true,
        });

        // Add a messages subcollection
        await tempDocRef.collection('messages').add({
          'senderId': 'setup',
          'senderName': 'System',
          'receiverId': 'setup',
          'message': 'Chat system initialized',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': true,
          'setupMessage': true,
        });

        print('Chat collections structure created successfully');
      }
    } catch (e) {
      print('Error setting up chat collections: $e');
    }
  }

  // Check if current user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Set up admin account (for development purposes)
  Future<void> setupAdminAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if admins collection exists
      final adminCheck = await _firestore.collection('admins').limit(1).get();

      // If no admins, create one for the current user (developer mode)
      if (adminCheck.docs.isEmpty) {
        print('Setting up admin account for development...');

        await _firestore.collection('admins').doc(user.uid).set({
          'userId': user.uid,
          'email': user.email,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Admin account created successfully');
      }
    } catch (e) {
      print('Error setting up admin account: $e');
    }
  }

  // Get current user display name
  Future<String> getCurrentUserName() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Guest';
    }

    String displayName = user.displayName ?? '';

    if (displayName.isEmpty) {
      try {
        // Try to get name from users collection
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            displayName = '$firstName $lastName'.trim();
          }
        }
      } catch (e) {
        print('Error getting user name: $e');
      }
    }

    return displayName.isNotEmpty ? displayName : 'User';
  }
}
