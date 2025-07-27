import 'package:flutter/material.dart';

class DrivingLicenseForm extends StatelessWidget {
  final VoidCallback onComplete;

  const DrivingLicenseForm({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving License'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Driving License',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please upload clear photos of your valid driving license',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.drive_eta),
                title: const Text('Front Side'),
                subtitle: const Text('Upload front side of license'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  // Implement front side upload
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.drive_eta),
                title: const Text('Back Side'),
                subtitle: const Text('Upload back side of license'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  // Implement back side upload
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Save License',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeaponLicenseForm extends StatelessWidget {
  final VoidCallback onComplete;

  const WeaponLicenseForm({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weapon License'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Weapon License',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please upload clear photos of your valid weapon license',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Front Side'),
                subtitle: const Text('Upload front side of license'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  // Implement front side upload
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Back Side'),
                subtitle: const Text('Upload back side of license'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  // Implement back side upload
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Save License',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChefCertificateForm extends StatelessWidget {
  final VoidCallback onComplete;

  const ChefCertificateForm({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef Certificates'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Cooking Certificates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload any cooking certifications you have (optional)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Certificate'),
                subtitle: const Text('Upload your cooking certificate'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  // Implement certificate upload
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Save Certificate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
