import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'provider_page.dart';
import '../app_screens/drawer/mydrawer.dart';
import '../services/location_picker.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'package:supabase/supabase.dart';

class WorkerRegistration extends StatefulWidget {
  const WorkerRegistration({super.key});

  @override
  State<WorkerRegistration> createState() => _WorkerRegistrationState();
}

class _WorkerRegistrationState extends State<WorkerRegistration> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  String? _selectedService;
  String? _selectedLocation;

  final List<String> _services = [
    'Security Guard',
    'Driver',
    'Maid',
    'Chef',
    'Gardener',
    'Handyman',
    'Locksmith',
    'Auto Mechanic',
    'Chef',
  ];

  final List<String> _locations = [
    'Johar Town',
    'Model Town',
    'Faisal Town',
    'Gulberg',
    'Lake City',
    'Valancia Town',
    'DHA',
    'Bahria Town',
    'WAPDA Town',
    'Allama Iqbal Town',
  ];

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance.collection('workers').doc(user.uid).set({
        'userId': user.uid,
        'cnic': _cnicController.text,
        'experience': _experienceController.text,
        'service': _selectedService,
        'location': _selectedLocation,
        'status': 'pending', // pending, approved, rejected
        'rating': 0.0,
        'completedJobs': 0,
        'registrationDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WorkerDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Registration'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      drawer: const MyDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cnicController,
                decoration: InputDecoration(
                  labelText: 'CNIC Number',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your CNIC number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: InputDecoration(
                  labelText: 'Select Service',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  labelStyle: TextStyle(
                    color:
                        _selectedService != null ? Colors.black : Colors.grey,
                  ),
                ),
                items: _services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a service';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                    TextEditingController(text: _selectedLocation ?? ''),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Service Location',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Use Current Location',
                        onPressed: () async {
                          final locationProvider =
                              Provider.of<LocationProvider>(context,
                                  listen: false);
                          await locationProvider.getCurrentLocation();
                          setState(() {
                            _selectedLocation = locationProvider.currentAddress;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        tooltip: 'Select on Map',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LocationPicker(
                                onLocationSelected: (lat, lng, address) {
                                  setState(() {
                                    _selectedLocation = address;
                                  });
                                  final locationProvider =
                                      Provider.of<LocationProvider>(context,
                                          listen: false);
                                  locationProvider.updateAddress(address,
                                      fullAddress: address);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if ((_selectedLocation ?? '').isEmpty) {
                    return 'Please select a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: 'Years of Experience',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: Colors.black),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.purple)
                    : const Text('Submit Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
