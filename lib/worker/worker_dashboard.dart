// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../service_provider/worker_drawer.dart';
import '../providers/notification_provider.dart';
import '../services/worker_service.dart';
import 'pending_bookings_tab.dart';
import 'active_negotiations_tab.dart';
import 'scheduled_services_tab.dart';
import 'completed_services_tab.dart';
import '../widgets/online_toggle.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkerService _workerService = WorkerService();
  String _workerName = '';
  bool _isLoading = true;
  bool _isOnline = false;
  double _walletBalance = 0.0;
  bool _walletLoaded = false;
  int _pendingRequests = 0;
  int _activeNegotiations = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWorkerData();
    _loadWalletBalance();
    _loadCounts();

    // Check if we need to navigate to a specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        if (args.containsKey('refresh') && args['refresh'] == true) {
          _loadWorkerData();
          _loadWalletBalance();
          _loadCounts();
        }

        if (args.containsKey('tab')) {
          final tab = args['tab'] as String;
          switch (tab) {
            case 'pending':
              _tabController.animateTo(0);
              break;
            case 'negotiations':
              _tabController.animateTo(1);
              break;
            case 'scheduled':
              _tabController.animateTo(2);
              break;
            case 'completed':
              _tabController.animateTo(3);
              break;
          }
        }
      }
    });
  }

  Future<void> _loadWorkerData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final workerDoc =
            await _firestore.collection('workers').doc(user.uid).get();

        if (workerDoc.exists) {
          final data = workerDoc.data();
          if (data != null) {
            // Check worker status
            final status = data['status']?.toString().toLowerCase() ?? '';
            if (status != 'approved') {
              // If not approved, redirect to pending approval page
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacementNamed(context, '/pending-approval');
              });
              return;
            }

            setState(() {
              _workerName =
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
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

  Future<void> _loadWalletBalance() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('workers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final revenueStr = data['revenue']?.toString() ?? '0';
          _walletBalance = double.tryParse(revenueStr) ?? 0.0;
        }
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
    } finally {
      setState(() {
        _walletLoaded = true;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() {
      _isLoading = true;
    });
    await _loadWalletBalance();
    if (_walletBalance < 200) {
      setState(() {
        _isOnline = false;
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.purple.shade50,
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.purple, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Insufficient Wallet Balance',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87),
              ),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'You need at least Rs 200 in your wallet to go online. Please top up your wallet.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK',
                  style: TextStyle(
                      color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }
    try {
      final newStatus = !_isOnline;
      await _workerService.updateOnlineStatus(newStatus);
      setState(() {
        _isOnline = newStatus;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now ${_isOnline ? 'online' : 'offline'}'),
          backgroundColor: _isOnline ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling online status: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCounts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Count pending requests
        final pendingSnapshot = await _firestore
            .collection('bookings')
            .where('workerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .count()
            .get();

        // Count active negotiations
        final negotiationsSnapshot = await _firestore
            .collection('negotiations')
            .where('workerId', isEqualTo: user.uid)
            .where('isAccepted', isEqualTo: false)
            .where('isRejected', isEqualTo: false)
            .count()
            .get();

        setState(() {
          _pendingRequests = pendingSnapshot.count ?? 0;
          _activeNegotiations = negotiationsSnapshot.count ?? 0;
        });
      }
    } catch (e) {
      print('Error loading counts: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Center(
                child: OnlineToggle(
                  isOnline: _isOnline,
                  onToggle: (bool value) async {
                    if (value) {
                      if (_isOnline) return; // Already online, do nothing
                      await _toggleOnlineStatus();
                    } else {
                      if (!_isOnline) return; // Already offline, do nothing
                      // Go offline immediately
                      await _workerService.updateOnlineStatus(false);
                      setState(() => _isOnline = false);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Notification icon with badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.yellow,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 13,
                          minHeight: 13,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 9
                              ? '9+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadCounts();
              setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.purple,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  child: _buildTabItem(
                    Icons.pending_actions,
                    'Pending Requests',
                    _pendingRequests,
                  ),
                ),
                Tab(
                  child: _buildTabItem(
                    Icons.handshake,
                    'Negotiations',
                    _activeNegotiations,
                  ),
                ),
                Tab(
                  child: _buildTabItem(
                    Icons.calendar_today,
                    'Scheduled',
                    0,
                  ),
                ),
                Tab(
                  child: _buildTabItem(
                    Icons.check_circle,
                    'Completed',
                    0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const WorkerDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: Colors.purple),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  PendingBookingsTab(),
                  ActiveNegotiationsTab(),
                  ScheduledServicesTab(),
                  CompletedServicesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String text, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
