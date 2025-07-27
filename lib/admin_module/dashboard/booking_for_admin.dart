import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../booking.dart';

class BookingPageForAdmin extends StatelessWidget {
  const BookingPageForAdmin({
    super.key,
  });

  Future<Map<String, String>> _getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      DocumentSnapshot addressDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('address')
          .doc('default')
          .get();

      String userName = userDoc.exists ? userDoc['full_name'] : 'Unknown User';
      String userAddress =
          addressDoc.exists ? addressDoc['address'] : 'No Address';

      return {
        'name': userName,
        'address': userAddress,
      };
    } catch (e) {
      return {
        'name': 'Unknown User',
        'address': 'No Address',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Bookings',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("bookings")
              .where("status", whereIn: [
                'pending',
                'completed'
              ]) // Show both pending and completed bookings
              .limit(20)
              .snapshots(), // Limit to 20 documents
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.purple));
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            } else if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No bookings!",
                  style: TextStyle(color: Colors.black),
                ),
              );
            } else {
              List<Booking> pendingBookings = [];
              List<Booking> completedBookings = [];

              for (var doc in snapshot.data!.docs) {
                Booking booking =
                    Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                if (booking.status == 'pending') {
                  pendingBookings.add(booking);
                } else if (booking.status == 'completed') {
                  completedBookings.add(booking);
                }
              }

              return ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                children: [
                  _buildBookingCategory(
                      context, 'Pending Bookings', pendingBookings),
                  _buildBookingCategory(
                      context, 'Completed Bookings', completedBookings),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBookingCategory(
      BuildContext context, String title, List<Booking> bookings) {
    return ExpansionTile(
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: false,
      children: bookings
          .map((booking) => _buildBookingItem(context, booking))
          .toList(),
    );
  }

  Widget _buildBookingItem(BuildContext context, Booking booking) {
    return FutureBuilder(
      future: _getUserData(booking.userId),
      builder: (context, AsyncSnapshot<Map<String, String>> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.purple));
        } else if (userSnapshot.hasError) {
          return Center(
            child: Text('Error: ${userSnapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        } else if (!userSnapshot.hasData ||
            userSnapshot.data == null ||
            userSnapshot.data!.isEmpty) {
          return const Text(
            'Error loading user data',
            style: TextStyle(color: Colors.black),
          );
        } else {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFeaeaea),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                booking.serviceName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${booking.status}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    'User: ${userSnapshot.data!['name']}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Address: ${userSnapshot.data!['address']}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              trailing: booking.status == 'pending'
                  ? _buildTrailingButtons(context, booking)
                  : null,
            ),
          );
        }
      },
    );
  }

  Widget _buildTrailingButtons(BuildContext context, Booking booking) {
    return ElevatedButton(
      onPressed: () => _completeBooking(context, booking),
      child: const Text(
        'Complete Booking',
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  void _completeBooking(BuildContext context, Booking booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': 'completed'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${booking.serviceName} booking marked as completed',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to complete booking: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
