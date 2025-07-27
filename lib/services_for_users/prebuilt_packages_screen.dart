import 'package:flutter/material.dart';
import '../models/service_package.dart';
import '../services/package_service.dart';

class PreBuiltPackagesScreen extends StatefulWidget {
  const PreBuiltPackagesScreen({super.key});

  @override
  State<PreBuiltPackagesScreen> createState() => _PreBuiltPackagesScreenState();
}

class _PreBuiltPackagesScreenState extends State<PreBuiltPackagesScreen> {
  final PackageService _packageService = PackageService();
  bool _isLoading = true;
  List<PreBuiltPackage> _packages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packages = await _packageService.getPreBuiltPackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading packages: $e';
      });
    }
  }

  Future<void> _subscribeToPackage(String packageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _packageService.createPackageFromPreBuilt(packageId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully subscribed to package!')),
      );

      // Navigate back or to packages list
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subscribing to package: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Built Packages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _packages.isEmpty
                  ? const Center(child: Text('No pre-built packages available'))
                  : ListView.builder(
                      itemCount: _packages.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        return _buildPackageCard(_packages[index]);
                      },
                    ),
    );
  }

  Widget _buildPackageCard(PreBuiltPackage package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Package Image
          if (package.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                package.imageUrl,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.purple.withOpacity(0.2),
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 50, color: Colors.purple),
                    ),
                  );
                },
              ),
            ),

          // Package Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${package.durationMonths} month${package.durationMonths > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  package.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Services included
                const Text(
                  'Services Included:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: package.includedServices.map((service) {
                    return Chip(
                      label: Text(service),
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Pricing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Package Price:',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${package.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save ${package.discount.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _subscribeToPackage(package.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
