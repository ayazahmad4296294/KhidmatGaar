import 'package:flutter/material.dart';
import '../../app_screens/home_page.dart';
import '../../utils/user_mode.dart';

class RegistrationDrawer extends StatelessWidget {
  const RegistrationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.purple,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Worker Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Complete your profile to get started',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.work, color: Colors.purple),
                  title: Text('1. Select Service'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.purple),
                  title: Text('2. Basic Information'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.credit_card, color: Colors.purple),
                  title: Text('3. CNIC Information'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.security, color: Colors.purple),
                  title: Text('4. Police Character Certificate'),
                  dense: true,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await UserMode.setWorkerMode(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
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
        ],
      ),
    );
  }
}
