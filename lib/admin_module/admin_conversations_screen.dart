import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../models/chat_message.dart';

class AdminConversationsScreen extends StatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  State<AdminConversationsScreen> createState() =>
      _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _chatService.getUsersForAdmin();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat(String userId, String userName, bool isWorker) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    try {
      // Create or get conversation
      final conversationId = await _chatService.createOrGetAdminConversation(
        userId: userId,
        userName: userName,
        isWorker: isWorker,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherPersonName: userName,
            otherPersonId: userId,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Existing conversations
          Expanded(
            flex: 1,
            child: StreamBuilder<List<ChatConversation>>(
              stream: _chatService.getUserConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.purple));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text('No active conversations'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Existing Conversations',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final isAdmin = _chatService.currentUserId ==
                              conversation.customerId;

                          // Get the user name based on admin's position
                          final otherPersonName = isAdmin
                              ? conversation.workerName
                              : conversation.customerName;

                          final otherPersonId = isAdmin
                              ? conversation.workerId
                              : conversation.customerId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                otherPersonName.isNotEmpty
                                    ? otherPersonName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: Colors.teal.shade800),
                              ),
                            ),
                            title: Text(otherPersonName),
                            subtitle: Text(
                              conversation.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: conversation.hasUnreadMessages
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
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
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Divider between sections
          const Divider(thickness: 1),

          // List of all users to start a chat
          Expanded(
            flex: 1,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Start New Conversation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final userId = user['id'] as String;
                            final userName = user['name'] as String;
                            final isWorker = user['isWorker'] as bool;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isWorker
                                    ? Colors.purple.shade100
                                    : Colors.blue.shade100,
                                child: Icon(
                                  isWorker ? Icons.work : Icons.person,
                                  color: isWorker ? Colors.purple : Colors.blue,
                                ),
                              ),
                              title: Text(userName.isEmpty
                                  ? 'User ${userId.substring(0, 4)}'
                                  : userName),
                              subtitle: Text(isWorker ? 'Worker' : 'Customer'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.chat, color: Colors.teal),
                                onPressed: () =>
                                    _startChat(userId, userName, isWorker),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
