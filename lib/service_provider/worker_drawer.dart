import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/user_mode.dart';
import '../app_screens/home_page.dart';
import '../services/worker_service.dart';
import 'worker_profile_page.dart';
import '../app_screens/drawer/about.dart';
import '../app_screens/drawer/privacy_policy.dart';
import '../app_screens/drawer/terms_and_conditions.dart';
import '../chat/conversations_screen.dart';
import '../app_screens/wallet_screen.dart';

class WorkerDrawer extends StatefulWidget {
  const WorkerDrawer({Key? key}) : super(key: key);

  @override
  State<WorkerDrawer> createState() => _WorkerDrawerState();
}

class _WorkerDrawerState extends State<WorkerDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkerService _workerStatusService = WorkerService();
  bool _isLoading = true;
  String _workerName = '';
  String _workerService = '';
  String _workerImageUrl = '';
  String _workerStatus = '';
  String _workerId = '';
  int _completedJobs = 0;
  double _rating = 0.0;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when drawer is opened
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('DEBUG: Worker Drawer - Loading worker data for: ${user.uid}');
        final workerDoc =
            await _firestore.collection('workers').doc(user.uid).get();

        if (workerDoc.exists) {
          final data = workerDoc.data();
          if (data != null) {
            // Force refresh the completed jobs count using the service
            final int completedJobs =
                await _workerStatusService.getCompletedJobsCount(user.uid);
            print(
                'DEBUG: Worker Drawer - Loaded completed jobs count from service: $completedJobs');

            setState(() {
              _workerId = user.uid;
              _workerName =
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
              _workerService = data['service'] ?? 'Service Provider';
              _workerImageUrl = data['profileImage'] ?? '';
              _workerStatus = data['status'] ?? 'pending';
              _rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
              _completedJobs = completedJobs;
              _isOnline = data['isOnline'] ?? false;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading worker data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      // Toggle the online status
      final newStatus = !_isOnline;

      // Update Firestore
      await _workerStatusService.updateOnlineStatus(newStatus);

      // Update local state
      setState(() {
        _isOnline = newStatus;
      });

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now ${_isOnline ? 'online' : 'offline'}'),
          backgroundColor: _isOnline ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling online status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    if (!context.mounted) return;

    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.purple.shade50,
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
              color: Colors.purple,
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
                color: Colors.purple,
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
      await _auth.signOut();
      if (!context.mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    _workerName.isNotEmpty ? _workerName : 'Worker',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    _workerService,
                    style: const TextStyle(fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _workerImageUrl.isNotEmpty
                        ? NetworkImage(_workerImageUrl)
                        : null,
                    child: _workerImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                  ),
                  otherAccountsPictures: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: CircleAvatar(
                          backgroundColor:
                              _isOnline ? Colors.green : Colors.grey,
                          radius: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.blue),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/worker-dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.teal),
                  title: const Text(
                    'My Profile',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    // Create a WorkerProfile object with the current worker data
                    final workerProfile = WorkerProfile(
                      id: _workerId,
                      name: _workerName,
                      image: _workerImageUrl.isNotEmpty
                          ? _workerImageUrl
                          : 'https://via.placeholder.com/150',
                      experience:
                          '${DateTime.now().year - 2020} years experience', // Default experience
                      completedJobs: _completedJobs,
                      rating: _rating,
                      preferredLocations: const [
                        'Lahore',
                        'Islamabad'
                      ], // Default locations
                      description:
                          'Professional $_workerService with experience in quality service delivery.',
                      service: _workerService,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkerProfilePage(worker: workerProfile),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.purple),
                  title: const Text(
                    'Chat With Customers',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to worker chat screen - conversations screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConversationsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.account_balance_wallet,
                      color: Colors.green, size: 24),
                  title: const Text(
                    'Wallet',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.indigo),
                  title: const Text(
                    'About Us',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.description, color: Colors.deepOrange),
                  title: const Text(
                    'Terms and Conditions',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.brown),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await UserMode.setWorkerMode(false);
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Switch to Customer Mode',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getStatusColor() {
    switch (_workerStatus.toLowerCase()) {
      case 'approved':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
