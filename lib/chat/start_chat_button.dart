import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class StartChatButton extends StatelessWidget {
  final String workerId;
  final String workerName;
  final IconData? icon;
  final String? label;
  final bool isIconButton;
  final Color? color;

  const StartChatButton({
    super.key,
    required this.workerId,
    required this.workerName,
    this.icon = Icons.chat,
    this.label = 'Chat',
    this.isIconButton = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconButton) {
      return IconButton(
        icon: Icon(icon, color: color ?? Colors.purple),
        onPressed: () => _startChat(context),
        tooltip: 'Chat with $workerName',
      );
    }

    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label ?? 'Chat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: () => _startChat(context),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to start a chat')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );

      // Initialize chat service
      final chatService = ChatService();

      // Check if user can chat based on booking status
      final chatEligibility =
          await chatService.canUsersChat(user.uid, workerId);

      if (!chatEligibility['canChat']) {
        // Close loading dialog
        Navigator.pop(context);

        // Show booking required dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Start Chat'),
            content: Text(chatEligibility['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to bookings page
                  Navigator.pushNamed(context, '/bookings');
                },
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        );
        return;
      }

      // If conversation already exists, navigate to it
      if (chatEligibility.containsKey('conversationId')) {
        // Close loading dialog
        Navigator.pop(context);

        // Navigate to existing conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: chatEligibility['conversationId'],
              otherPersonName: workerName,
              otherPersonId: workerId,
            ),
          ),
        );
        return;
      }

      // Get customer name
      String customerName = user.displayName ?? 'User';
      if (customerName == 'User') {
        // Try to get name from users collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            customerName =
                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                    .trim();
            if (customerName.isEmpty) {
              customerName = 'User';
            }
          }
        }
      }

      try {
        // Create new conversation
        final conversationId = await chatService.createOrGetConversation(
          customerId: user.uid,
          customerName: customerName,
          workerId: workerId,
          workerName: workerName,
        );

        // Close loading dialog
        Navigator.pop(context);

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherPersonName: workerName,
              otherPersonId: workerId,
            ),
          ),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);

        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      // Show error
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }
}
