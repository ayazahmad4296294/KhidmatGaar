import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../services/firebase_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    final isAdmin = await _firebaseService.isUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Admin Conversations' : 'Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: _chatService.getUserConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdmin 
                        ? 'You don\'t have any active conversations'
                        : 'You can only chat with workers after a booking has been confirmed by both sides',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_isAdmin) 
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/admin-conversations');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Start New Conversation'),
                      ),
                    ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation);
            },
          );
        },
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin-conversations');
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_comment),
      ) : null,
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final currentUserId = _chatService.currentUserId;
    final isCustomer = currentUserId == conversation.customerId;

    // Determine who the other person is
    final otherPersonName =
        isCustomer ? conversation.workerName : conversation.customerName;

    final otherPersonId =
        isCustomer ? conversation.workerId : conversation.customerId;

    // Format the last message time
    final lastMessageTime =
        DateFormat.jm().format(conversation.lastMessageTime);
    final isToday = conversation.lastMessageTime.day == DateTime.now().day;
    final isYesterday = conversation.lastMessageTime.day ==
        DateTime.now().subtract(const Duration(days: 1)).day;

    String dateString;
    if (isToday) {
      dateString = lastMessageTime;
    } else if (isYesterday) {
      dateString = 'Yesterday';
    } else {
      dateString = DateFormat('MMM d').format(conversation.lastMessageTime);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.purple.shade100,
        child: Text(
          otherPersonName.isNotEmpty ? otherPersonName[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.purple.shade800),
        ),
      ),
      title: Text(
        otherPersonName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateString,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          if (conversation.hasUnreadMessages)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherPersonName: otherPersonName,
              otherPersonId: otherPersonId,
            ),
          ),
        );
      },
    );
  }
}
