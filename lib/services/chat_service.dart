import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user id
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if a confirmed booking exists between customer and worker
  Future<bool> hasConfirmedBooking(String customerId, String workerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: customerId)
          .where('workerId', isEqualTo: workerId)
          .where('status', whereIn: ['confirmed', 'in_progress', 'completed'])
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking booking status: $e');
      return false;
    }
  }

  // Create a new conversation or get existing one
  Future<String> createOrGetConversation({
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
  }) async {
    try {
      // Check if conversation already exists
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('customerId', isEqualTo: customerId)
          .where('workerId', isEqualTo: workerId)
          .limit(1)
          .get();

      // If conversation exists, return its ID
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs[0].id;
      }

      // Check if there's a confirmed booking between the customer and worker
      bool bookingExists = await hasConfirmedBooking(customerId, workerId);
      if (!bookingExists) {
        throw Exception(
            'You can only chat with a worker after a booking is confirmed by both sides');
      }

      // Otherwise, create a new conversation
      final newConversation = ChatConversation(
        id: '',
        customerId: customerId,
        customerName: customerName,
        workerId: workerId,
        workerName: workerName,
        lastMessageTime: DateTime.now(),
        lastMessage: 'New conversation started',
        hasUnreadMessages: false,
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(newConversation.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user display name or fetch it from users collection
      String senderName = user.displayName ?? 'User';
      if (senderName == 'User') {
        // Try to get name from users collection
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            senderName =
                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                    .trim();
            if (senderName.isEmpty) {
              senderName = 'User';
            }
          }
        }
      }

      // Create message
      final newMessage = ChatMessage(
        id: '',
        senderId: user.uid,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
      );

      // Save message to conversation messages subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(newMessage.toMap());

      // Get the conversation to determine if user is customer or worker
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final conversationData = conversationDoc.data();
      if (conversationData == null) {
        throw Exception('Conversation data is null');
      }

      // Determine if the current user is the customer or worker
      final isCustomer = user.uid == conversationData['customerId'];

      // Update conversation with last message
      final updateData = {
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'hasUnreadMessages': true,
      };

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get all conversations for a user (either as customer or worker)
  Stream<List<ChatConversation>> getUserConversations() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('conversations')
        .where(Filter.or(
          Filter('customerId', isEqualTo: user.uid),
          Filter('workerId', isEqualTo: user.uid),
        ))
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatConversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all messages for a specific conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Mark all messages as read for a user
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all unread messages sent to the current user
      final querySnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Create a batch write to update all messages at once
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // If there were unread messages, update conversation status too
      if (querySnapshot.docs.isNotEmpty) {
        batch.update(
          _firestore.collection('conversations').doc(conversationId),
          {'hasUnreadMessages': false},
        );
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Utility method to check if customer and worker can chat
  Future<Map<String, dynamic>> canUsersChat(
      String customerId, String workerId) async {
    try {
      // Check if there's a confirmed booking
      final hasBooking = await hasConfirmedBooking(customerId, workerId);

      if (!hasBooking) {
        return {
          'canChat': false,
          'message':
              'You can only chat with a worker after a booking is confirmed by both sides'
        };
      }

      // Check if conversation already exists
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('customerId', isEqualTo: customerId)
          .where('workerId', isEqualTo: workerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {
          'canChat': true,
          'message': 'Conversation exists',
          'conversationId': querySnapshot.docs[0].id
        };
      }

      return {'canChat': true, 'message': 'Can create new conversation'};
    } catch (e) {
      print('Error checking if users can chat: $e');
      return {
        'canChat': false,
        'message': 'Error checking chat eligibility: $e'
      };
    }
  }

  // Admin specific methods
  
  // Check if user is admin
  Future<bool> isUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Create or get conversation with a user from admin
  Future<String> createOrGetAdminConversation({
    required String userId,
    required String userName,
    required bool isWorker,
  }) async {
    try {
      final adminUser = _auth.currentUser;
      if (adminUser == null) {
        throw Exception('Admin not authenticated');
      }
      
      // Get admin name
      String adminName = 'Khidmat Admin';
      
      // Check if conversation already exists
      final querySnapshot = await _firestore
          .collection('conversations')
          .where(isWorker ? 'workerId' : 'customerId', isEqualTo: userId)
          .where(isWorker ? 'customerId' : 'workerId', isEqualTo: adminUser.uid)
          .limit(1)
          .get();
      
      // If conversation exists, return its ID
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs[0].id;
      }
      
      // Create a new conversation
      final conversationData = isWorker 
        ? {
            'customerId': adminUser.uid,
            'customerName': adminName,
            'workerId': userId,
            'workerName': userName,
            'lastMessageTime': Timestamp.fromDate(DateTime.now()),
            'lastMessage': 'New conversation started',
            'hasUnreadMessages': false,
            'isAdminConversation': true,
          }
        : {
            'customerId': userId,
            'customerName': userName,
            'workerId': adminUser.uid,
            'workerName': adminName,
            'lastMessageTime': Timestamp.fromDate(DateTime.now()),
            'lastMessage': 'New conversation started',
            'hasUnreadMessages': false,
            'isAdminConversation': true,
          };
      
      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData);
      
      return docRef.id;
    } catch (e) {
      print('Error creating admin conversation: $e');
      rethrow;
    }
  }
  
  // Get all users and workers for admin to message
  Future<List<Map<String, dynamic>>> getUsersForAdmin() async {
    try {
      final List<Map<String, dynamic>> users = [];
      
      // Get customers
      final customerSnapshot = await _firestore.collection('users').get();
      for (var doc in customerSnapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'isWorker': false,
        });
      }
      
      // Get workers
      final workerSnapshot = await _firestore.collection('workers').get();
      for (var doc in workerSnapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'isWorker': true,
        });
      }
      
      return users;
    } catch (e) {
      print('Error fetching users for admin: $e');
      return [];
    }
  }
}
