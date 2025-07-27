import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import '../email_auth/login_page.dart';
import '../service_provider/registration/worker_registration_steps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service_provider/registration/pending_approval_page.dart';
import '../worker/worker_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final bool isWorkerMode;

  const SplashScreen({super.key, required this.isWorkerMode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (widget.isWorkerMode) {
        // Check if worker exists and their status
        final workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (!workerDoc.exists) {
          // Not registered, show registration
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const WorkerRegistrationSteps()),
          );
          return;
        }

        final workerData = workerDoc.data() as Map<String, dynamic>;
        final status = (workerData['status'] ?? '').toString().toLowerCase();
        if (status == 'pending') {
          // Registration pending approval
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PendingApprovalPage()),
          );
          return;
        }
        if (status == 'approved') {
          // Worker is approved, go directly to dashboard
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WorkerDashboard()),
          );
          return;
        }
        // If rejected or other status, show registration
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const WorkerRegistrationSteps()),
        );
        return;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          height: 220,
          width: 220,
          child: Image(
            image: AssetImage('assets/Logo.png'),
            width: 250,
            height: 250,
          ),
        ),
      ),
    );
  }
}
