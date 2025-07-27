import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app_screens/drawer/mydrawer.dart';

class ElectricianForAdmin extends StatelessWidget {
  const ElectricianForAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Electricians', style: TextStyle(color: Colors.black)),
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  displayService(context);
                },
                child: const Text(
                  'Add Service',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("On_Demand_Services")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> userMap =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFeaeaea),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              title: Text(
                                userMap["service_name"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                userMap["price"],
                                style: const TextStyle(color: Colors.black),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                    ),
                                    onPressed: () {
                                      editService(
                                          context,
                                          snapshot.data!.docs[index].id,
                                          userMap);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                    ),
                                    onPressed: () {
                                      deleteService(context,
                                          snapshot.data!.docs[index].id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text(
                          "No data!",
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }
                  } else {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.purple));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void displayService(BuildContext context) {
    TextEditingController serviceNameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    String serviceNameError = '';
    String priceError = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Add Electrician Service",
                style: TextStyle(color: Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: serviceNameController,
                    decoration: InputDecoration(
                      labelText: "Service Name",
                      labelStyle: const TextStyle(color: Colors.black),
                      errorText:
                          serviceNameError.isNotEmpty ? serviceNameError : null,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: "Price",
                      labelStyle: const TextStyle(color: Colors.black),
                      errorText: priceError.isNotEmpty ? priceError : null,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      serviceNameError =
                          serviceNameController.text.trim().isEmpty
                              ? 'Please enter a service name'
                              : '';
                      priceError = priceController.text.trim().isEmpty
                          ? 'Please enter a price'
                          : '';
                    });

                    if (serviceNameError.isEmpty && priceError.isEmpty) {
                      addNewService(
                          context, serviceNameController, priceController);
                    }
                  },
                  child:
                      const Text("Save", style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addNewService(
      BuildContext context,
      TextEditingController serviceNameController,
      TextEditingController priceController) {
    String serviceName = serviceNameController.text.trim();
    String price = priceController.text.trim();
    String serviceNameError = '';
    String priceError = '';

    if (serviceName.isEmpty) {
      serviceNameError = 'Please enter a service name';
    }
    if (price.isEmpty) {
      priceError = 'Please enter a price';
    }

    if (serviceNameError.isEmpty && priceError.isEmpty) {
      Map<String, dynamic> userData = {
        "service_name": serviceName,
        "price": price,
      };
      FirebaseFirestore.instance.collection("On_Demand_Services").add(userData);
      log("Electrician service added!");

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully!')),
      );
    }
  }

  void editService(
      BuildContext context, String docId, Map<String, dynamic> userMap) {
    TextEditingController serviceNameController =
        TextEditingController(text: userMap["service_name"]);
    TextEditingController priceController =
        TextEditingController(text: userMap["price"]);
    String serviceNameError = '';
    String priceError = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Edit Electrician Service",
                style: TextStyle(color: Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: serviceNameController,
                    decoration: InputDecoration(
                      labelText: "Service Name",
                      labelStyle: const TextStyle(color: Colors.black),
                      errorText:
                          serviceNameError.isNotEmpty ? serviceNameError : null,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: "Price",
                      labelStyle: const TextStyle(color: Colors.black),
                      errorText: priceError.isNotEmpty ? priceError : null,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      serviceNameError =
                          serviceNameController.text.trim().isEmpty
                              ? 'Please enter a service name'
                              : '';
                      priceError = priceController.text.trim().isEmpty
                          ? 'Please enter a price'
                          : '';
                    });

                    if (serviceNameError.isEmpty && priceError.isEmpty) {
                      FirebaseFirestore.instance
                          .collection("On_Demand_Services")
                          .doc(docId)
                          .update({
                        "service_name": serviceNameController.text,
                        "price": priceController.text,
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Service edited successfully!')),
                      );
                    }
                  },
                  child:
                      const Text("Save", style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteService(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Delete Service",
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            "Are you sure you want to delete this service?",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("On_Demand_Services")
                    .doc(docId)
                    .delete();
                Navigator.of(context).pop();
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
}
