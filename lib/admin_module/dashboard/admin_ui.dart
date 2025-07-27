import 'package:flutter/material.dart';
import 'package:khidmat/admin_module/dashboard/all_users.dart';
import 'package:khidmat/admin_module/dashboard/booking_for_admin.dart';
import 'package:khidmat/admin_module/services_for_admin/electrician_admin.dart';
import 'package:khidmat/admin_module/send_promotional_notification.dart';
import 'package:khidmat/admin_module/admin_conversations_screen.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Welcome to Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildGridItem(
                      context,
                      icon: Icons.people,
                      title: 'All Users',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllUsersPage(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.assignment,
                      title: 'Bookings',
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookingPageForAdmin(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.electrical_services,
                      title: 'Electricians',
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ElectricianForAdmin(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.handyman,
                      title: 'Other Services',
                      color: Colors.greenAccent,
                      onTap: () {
                        // This can be updated to navigate to a different service page if needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This feature is not yet available'),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.notifications_active,
                      title: 'Send Promotional Notifications',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SendPromotionalNotificationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.chat,
                      title: 'Direct Messages',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminConversationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
