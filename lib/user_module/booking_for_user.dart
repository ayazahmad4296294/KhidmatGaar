import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khidmat/user_module/account_management.dart';
import '../app_screens/home_page.dart';
import 'widgets/booking_card.dart';

class BookingPageForUser extends StatefulWidget {
  const BookingPageForUser({super.key});

  @override
  State<BookingPageForUser> createState() => _BookingPageForUserState();
}

class _BookingPageForUserState extends State<BookingPageForUser> {
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add filter options here
            ListTile(
              title: const Text('All'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Pending'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Completed'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          }

          final bookings = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              return BookingCard(booking: booking);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index != 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    index == 0 ? const HomePage() : const UserProfilePage(),
              ),
            );
          }
        },
      ),
    );
  }
}
