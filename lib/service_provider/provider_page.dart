import 'package:flutter/material.dart';

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the actual worker dashboard in the worker module
    return const ActualWorkerDashboard();
  }
}

// This class is used to redirect to the actual worker dashboard
class ActualWorkerDashboard extends StatelessWidget {
  const ActualWorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a builder to avoid a rebuild loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/worker-dashboard');
    });

    // Show a loading indicator while redirecting
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );
  }
}
