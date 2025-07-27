// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class SendPromotionalNotificationScreen extends StatefulWidget {
  const SendPromotionalNotificationScreen({Key? key}) : super(key: key);

  @override
  State<SendPromotionalNotificationScreen> createState() =>
      _SendPromotionalNotificationScreenState();
}

class _SendPromotionalNotificationScreenState
    extends State<SendPromotionalNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _notificationService = NotificationService();
  final _firestore = FirebaseFirestore.instance;

  bool _isSending = false;
  bool _selectAll = false;
  List<Map<String, dynamic>> _users = [];
  Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _users = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name':
                      '${doc.data()['firstName'] ?? ''} ${doc.data()['lastName'] ?? ''}'
                          .trim(),
                  'email': doc.data()['email'] ?? '',
                  'isWorker': doc.data()['isWorker'] ?? false,
                })
            .toList();
      });
    } catch (e) {
      _showErrorDialog('Error loading users: $e');
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedUserIds = _users.map((user) => user['id'] as String).toSet();
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        _selectAll = false;
      } else {
        _selectedUserIds.add(userId);
        if (_selectedUserIds.length == _users.length) {
          _selectAll = true;
        }
      }
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserIds.isEmpty) {
      _showErrorDialog(
          'Please select at least one user to send the notification to.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Create a batch to add all notifications at once
      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');

      for (String userId in _selectedUserIds) {
        final notificationData = {
          'userId': userId,
          'title': _titleController.text,
          'body': _bodyController.text,
          'type': 'promotional',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': {
            'type': 'promotional',
          },
        };

        // Add to batch
        batch.set(notificationsRef.doc(), notificationData);
      }

      // Commit batch
      await batch.commit();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification sent to ${_selectedUserIds.length} users',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      _showErrorDialog('Error sending notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Promotional Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Notification Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Select Recipients:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (_) => _toggleSelectAll(),
                      ),
                      const Text('Select All'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _users.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.purple))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final userId = user['id'] as String;
                          final isSelected = _selectedUserIds.contains(userId);

                          return CheckboxListTile(
                            title: Text(user['name'] as String),
                            subtitle: Text(user['email'] as String),
                            secondary: Icon(
                              user['isWorker'] as bool
                                  ? Icons.work
                                  : Icons.person,
                            ),
                            value: isSelected,
                            onChanged: (_) => _toggleUserSelection(userId),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.purple)
                      : const Text(
                          'Send Notification',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
