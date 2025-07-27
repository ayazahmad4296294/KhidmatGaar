import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../booking.dart';
import '../app_screens/drawer/mydrawer.dart';

class MonthlyHiring extends StatelessWidget {
  const MonthlyHiring({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Hiring',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Monthly_Services")
              .snapshots(),
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
                  child: Text("No data available!",
                      style: TextStyle(color: Colors.black)));
            } else {
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> serviceMap =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFeaeaea),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        serviceMap["service_name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        serviceMap["price"],
                        style: const TextStyle(color: Colors.black),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _bookService(context, serviceMap);
                        },
                        child: const Text(
                          'Book Service',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _bookService(
      BuildContext context, Map<String, dynamic> serviceMap) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar(context, 'You need to log in to book a service');
      return;
    }

    String address = await _getAddress(context, user.uid);
    if (address.isEmpty) {
      _showErrorSnackBar(context, 'Address cannot be empty');
      return;
    }

    final booking = Booking(
      id: FirebaseFirestore.instance.collection('bookings').doc().id,
      serviceName: serviceMap["service_name"],
      serviceType: 'plumber',
      userId: user.uid,
      status: 'pending',
      address: address,
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${serviceMap["service_name"]} booked successfully',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to book service: ${e.toString()}');
    }
  }

  Future<String> _getAddress(BuildContext context, String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    String address = userData?['address'] ?? '';
    TextEditingController addressController =
        TextEditingController(text: address);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Address',
              style: TextStyle(color: Colors.black)),
          content: TextField(
            controller: addressController,
            onChanged: (value) {
              address = value;
            },
            decoration: const InputDecoration(hintText: "Address"),
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                address = addressController.text.trim();
                Navigator.of(context).pop();
              },
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );

    if (address.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'address': address});
    }

    return address;
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
