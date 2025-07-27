// ignore_for_file: unused_field

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/conversations_screen.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _userName = '';
  String _phoneNumber = '';
  String _email = '';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['full_name'] ?? '';
            _phoneNumber = userDoc['phone_number'] ?? '';
            _email = currentUser.email ?? '';

            _nameController.text = _userName;
            _phoneController.text = _phoneNumber;
            _emailController.text = _email;
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData(String userId) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      });
      setState(() {
        _userName = _nameController.text.trim();
        _phoneNumber = _phoneController.text.trim();
        _isEditing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  void _navigateToConversations() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConversationsScreen(),
        ),
      ).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString().split('\n').first}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettingsItem({
    required String title,
    required IconData icon,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.purple,
    bool showDivider = true,
    bool isEditable = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          trailing: isEditable
              ? Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400)
              : null,
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 60,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserData(FirebaseAuth.instance.currentUser?.uid ?? '');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserData(FirebaseAuth.instance.currentUser?.uid ?? '');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.purple.shade50,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.purple.shade700, size: 28),
            const SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Column(
              children: [
                _buildProfileHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildSettingsItem(
                        title: 'Full Name',
                        subtitle: _userName,
                        icon: Icons.person_outline,
                        onTap: _showEditNameDialog,
                        isEditable: true,
                        iconColor: Colors.purple.shade700,
                      ),
                      _buildSettingsItem(
                        title: 'Email',
                        subtitle: _email,
                        icon: Icons.email_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email cannot be changed'),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        },
                        iconColor: Colors.blue.shade700,
                      ),
                      _buildSettingsItem(
                        title: 'Phone Number',
                        subtitle: _phoneNumber.isNotEmpty
                            ? _phoneNumber
                            : 'Add phone number',
                        icon: Icons.phone_outlined,
                        onTap: _showEditPhoneDialog,
                        isEditable: true,
                        iconColor: Colors.teal.shade700,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'App Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildSettingsItem(
                        title: 'Logout',
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red.shade700,
                        onTap: () => logout(context),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
