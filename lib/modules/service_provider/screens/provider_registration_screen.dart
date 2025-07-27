import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/provider_home_screen.dart';

class ServiceProviderRegistration extends StatefulWidget {
  const ServiceProviderRegistration({super.key});

  @override
  State<ServiceProviderRegistration> createState() =>
      _ServiceProviderRegistrationState();
}

class _ServiceProviderRegistrationState
    extends State<ServiceProviderRegistration> {
  final _formKey = GlobalKey<FormState>();
  String selectedService = 'Security Guard';
  final List<String> services = [
    'Security Guard',
    'Gardener', 
    'Driver',
    'Baby Caretaker',
    'Chef',
    'Handyman',
    'Locksmith',
    'Auto Mechanic',
    'Maid'
  ];

  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _monthlyRateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedService,
                decoration: const InputDecoration(
                  labelText: 'Select Service Type',
                  border: OutlineInputBorder(),
                ),
                items: services.map((String service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedService = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (PKR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hourly rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Rate (PKR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter monthly rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitRegistration,
                child: const Text('Register as Service Provider'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('service_providers')
              .doc(user.uid)
              .set({
            'serviceType': selectedService,
            'experience': _experienceController.text,
            'hourlyRate': double.parse(_hourlyRateController.text),
            'monthlyRate': double.parse(_monthlyRateController.text),
            'isAvailable': true,
            'rating': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProviderHomeScreen(),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
