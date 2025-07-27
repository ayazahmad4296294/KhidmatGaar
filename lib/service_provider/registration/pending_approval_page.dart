import 'package:flutter/material.dart';
import '../../app_screens/home_page.dart';
import '../../utils/user_mode.dart';
import 'approved_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../worker/worker_dashboard.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  bool _isLoading = true;
  String _workerStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _checkWorkerStatus();
  }

  Future<void> _checkWorkerStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          final data = workerDoc.data();
          if (data != null) {
            // Get status and normalize to lowercase for case-insensitive comparison
            final status =
                data['status']?.toString().toLowerCase() ?? 'pending';

            setState(() {
              _workerStatus = status;
              _isLoading = false;
            });

            // If worker is already approved, navigate to dashboard
            if (status == 'approved') {
              // Use Future.delayed to avoid calling Navigator during build
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkerDashboard()),
                );
              });
            }
          }
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking worker status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registration Status'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    // Show appropriate UI based on status
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Status'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _workerStatus == 'rejected'
                    ? Icons.cancel
                    : Icons.pending_actions,
                size: 80,
                color: _workerStatus == 'rejected' ? Colors.red : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                _workerStatus == 'rejected'
                    ? 'Registration Rejected'
                    : 'Registration Pending Approval',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _workerStatus == 'rejected'
                    ? 'Your registration was not approved. Please contact support or reapply with corrected information.'
                    : 'Your registration is under review. We will notify you once it\'s approved.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await UserMode.setWorkerMode(false);
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.switch_account, color: Colors.white),
                label: const Text('Switch to Customer Mode',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: const Size(double.infinity, 48),
                  shadowColor: Colors.purpleAccent.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 16),
              // Refresh button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _checkWorkerStatus();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Check Status Again',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: const Size(double.infinity, 48),
                  shadowColor: Colors.greenAccent.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
