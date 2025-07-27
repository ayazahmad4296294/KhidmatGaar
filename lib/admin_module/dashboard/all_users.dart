import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class AllUsersPage extends StatelessWidget {
  const AllUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }
          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    user['full_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user['phone_number'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      editUser(context, users[index].id, user);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void displayUserForm(BuildContext context, {String? docId, Map<String, dynamic>? userMap}) {
    final fullNameController = TextEditingController(text: userMap?['full_name']);
    final phoneNumberController = TextEditingController(text: userMap?['phone_number']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                updateUser(docId!, fullNameController, phoneNumberController);
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void updateUser(String docId, TextEditingController fullNameController, TextEditingController phoneNumberController) {
    String fullName = fullNameController.text.trim();
    String phoneNumber = phoneNumberController.text.trim();

    if (fullName.isNotEmpty && phoneNumber.isNotEmpty) {
      FirebaseFirestore.instance.collection("users").doc(docId).update({
        "full_name": fullName,
        "phone_number": phoneNumber,
      });
      developer.log("User updated!");
    } else {
      developer.log("Please fill all the fields!");
    }
  }

  void editUser(BuildContext context, String docId, Map<String, dynamic> userMap) {
    displayUserForm(context, docId: docId, userMap: userMap);
  }
}
