// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_package.dart';
import '../services/package_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prebuilt_packages_screen.dart';

class PackageCreationScreen extends StatefulWidget {
  const PackageCreationScreen({super.key});

  @override
  State<PackageCreationScreen> createState() => _PackageCreationScreenState();
}

class _PackageCreationScreenState extends State<PackageCreationScreen> {
  final PackageService _packageService = PackageService();
  final List<ServicePackageItem> _selectedServices = [];
  int _selectedDuration = 1; // Default 1 month
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableServices = [];

  double _totalBeforeDiscount = 0;
  double _totalAfterDiscount = 0;
  double _discountPercentage = 3.0; // Default for 1 month

  @override
  void initState() {
    super.initState();
    _loadAvailableServices();
  }

  Future<void> _loadAvailableServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all available services from worker collection
      final workersSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .where('status', isEqualTo: 'approved')
          .get();

      // Create a set of unique services
      final Set<String> uniqueServices = {};
      final List<Map<String, dynamic>> services = [];

      for (var doc in workersSnapshot.docs) {
        final data = doc.data();
        final serviceName = data['service'] ?? '';
        if (serviceName.isNotEmpty && !uniqueServices.contains(serviceName)) {
          uniqueServices.add(serviceName);

          // Find a worker that offers this service
          final workers = await FirebaseFirestore.instance
              .collection('workers')
              .where('service', isEqualTo: serviceName)
              .where('status', isEqualTo: 'approved')
              .limit(1)
              .get();

          if (workers.docs.isNotEmpty) {
            final workerData = workers.docs.first.data();
            final workerId = workers.docs.first.id;

            // Determine price based on the service
            double price = 0.0;
            switch (serviceName.toLowerCase()) {
              case 'maid':
                price = 2500.0;
                break;
              case 'cook':
                price = 3000.0;
                break;
              case 'driver':
                price = 2800.0;
                break;
              case 'security guard':
                price = 3500.0;
                break;
              case 'baby care taker':
                price = 4000.0;
                break;
              case 'gardener':
                price = 2200.0;
                break;
              case 'handyman':
                price = 3200.0;
                break;
              case 'locksmith':
                price = 4500.0;
                break;
              case 'auto mechanic':
                price = 3800.0;
                break;
              case 'chef':
                price = 5000.0;
                break;
              default:
                price = 3000.0;
            }

            services.add({
              'serviceId': serviceName.toLowerCase(),
              'serviceName': serviceName,
              'workerId': workerId,
              'workerName':
                  '${workerData['firstName'] ?? ''} ${workerData['lastName'] ?? ''}',
              'price': price,
            });
          }
        }
      }

      setState(() {
        _availableServices = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
    }
  }

  void _toggleServiceSelection(Map<String, dynamic> service) {
    // Check if service is already selected
    final index = _selectedServices
        .indexWhere((item) => item.serviceId == service['serviceId']);

    setState(() {
      if (index >= 0) {
        // Remove service if already selected
        _selectedServices.removeAt(index);
      } else {
        // Add service if not selected
        _selectedServices.add(ServicePackageItem(
          serviceId: service['serviceId'],
          serviceName: service['serviceName'],
          price: service['price'],
          workerId: service['workerId'],
          workerName: service['workerName'],
        ));
      }

      // Recalculate totals
      _calculateTotals();
    });
  }

  void _updateDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
      // Update discount percentage based on duration
      _discountPercentage = ServicePackage.getDiscountPercentage(duration);
      // Recalculate totals
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _totalBeforeDiscount = _packageService.calculateTotalBeforeDiscount(
        _selectedServices, _selectedDuration);
    _totalAfterDiscount = _packageService.calculateFinalPrice(
        _selectedServices, _selectedDuration);
  }

  Future<void> _createPackage() async {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create the package
      final package = ServicePackage(
        userId: user.uid,
        items: _selectedServices,
        durationMonths: _selectedDuration,
        totalBeforeDiscount: _totalBeforeDiscount,
        totalAfterDiscount: _totalAfterDiscount,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final packageId = await _packageService.createPackage(package);

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package created successfully!')),
      );

      // Navigate to user packages screen or back
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating package: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Package'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreBuiltPackagesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.card_giftcard, color: Colors.amber),
            label: const Text(
              'Pre-Built',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with pre-built package link
                  Card(
                    color: Colors.amber.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Looking for convenience?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try our pre-built packages with bundled services and special discounts.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PreBuiltPackagesScreen(),
                                ),
                              );
                            },
                            child: const Text('View Packages'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Services Selection
                  const Text(
                    'Select Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildServicesList(),
                  const SizedBox(height: 24),

                  // Duration Selection
                  const Text(
                    'Package Duration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDurationSelector(),
                  const SizedBox(height: 24),

                  // Package Summary
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Package Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Services:'),
                              Text('${_selectedServices.length}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Duration:'),
                              Text('${_selectedDuration} month(s)'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total before discount:'),
                              Text(
                                'PKR ${_totalBeforeDiscount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Discount (${_discountPercentage.toStringAsFixed(1)}%):'),
                              Text(
                                'PKR ${(_totalBeforeDiscount - _totalAfterDiscount).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Final Price:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'PKR ${_totalAfterDiscount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Package Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedServices.isEmpty ? null : _createPackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        'Create Package',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildServicesList() {
    if (_availableServices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No services available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableServices.length,
      itemBuilder: (context, index) {
        final service = _availableServices[index];
        final isSelected = _selectedServices
            .any((item) => item.serviceId == service['serviceId']);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.purple.withOpacity(0.1) : null,
          child: ListTile(
            title: Text(service['serviceName']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Provider: ${service['workerName']}'),
                Text(
                  'Price: PKR ${service['price'].toStringAsFixed(2)}/month',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Checkbox(
              value: isSelected,
              activeColor: Colors.purple,
              onChanged: (value) => _toggleServiceSelection(service),
            ),
            onTap: () => _toggleServiceSelection(service),
          ),
        );
      },
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDurationOption(1),
        ),
        Expanded(
          child: _buildDurationOption(2),
        ),
        Expanded(
          child: _buildDurationOption(3),
        ),
      ],
    );
  }

  Widget _buildDurationOption(int months) {
    final isSelected = _selectedDuration == months;
    final discount = ServicePackage.getDiscountPercentage(months);

    return GestureDetector(
      onTap: () => _updateDuration(months),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.purple.withOpacity(0.1) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                '$months month${months > 1 ? 's' : ''}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$discount% off',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
