import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'conversations_screen.dart';

class ChatNavigation {
  // Add a chat icon in the app bar
  static Widget buildChatIcon(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chat),
      tooltip: 'Conversations',
      onPressed: () => navigateToConversations(context),
    );
  }

  // Navigate to conversations screen
  static void navigateToConversations(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to access chat')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationsScreen(),
      ),
    );
  }

  // Bottom navigation bar item for chat
  static BottomNavigationBarItem get bottomNavItem {
    return const BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      activeIcon: Icon(Icons.chat_bubble),
      label: 'Chats',
    );
  }

  // Handle bottom navigation tap for chat tab
  static bool handleBottomNavTap(
      BuildContext context, int index, int chatTabIndex) {
    if (index == chatTabIndex) {
      navigateToConversations(context);
      return true;
    }
    return false;
  }
}
