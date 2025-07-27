// ignore_for_file: unused_field, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_detail_page.dart';

class OnDemandService extends StatefulWidget {
  final Map<String, dynamic>? filters;

  const OnDemandService({super.key, this.filters});

  @override
  State<OnDemandService> createState() => _OnDemandServiceState();
}

class _OnDemandServiceState extends State<OnDemandService> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First try to get services from On_Demand_Services collection
      final QuerySnapshot snapshot =
          await _firestore.collection('On_Demand_Services').get();

      List<Map<String, dynamic>> services = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Service from On_Demand_Services: ${data['service_name']}');
        return {
          'id': doc.id,
          'title': data['service_name'] ?? 'Unknown Service',
          'description': data['service_description'] ??
              _getServiceDescription(data['service_name'] ?? ''),
          'icon': _getServiceIcon(data['service_name'] ?? ''),
          'color': _getServiceColor(data['service_name'] ?? ''),
          'locations': _getDefaultLocations(),
          'isNegotiable': data['price_negotiation_enabled'] ?? false,
        };
      }).toList();

      // Now directly check for available services in the workers collection
      final workersSnapshot = await _firestore
          .collection('workers')
          .where('status', isEqualTo: 'approved')
          .get();

      // Extract unique service names
      final Set<String> workerServices = {};
      for (var doc in workersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['service'] != null && data['service'].toString().isNotEmpty) {
          final service = data['service'].toString();

          // Only include non-monthly services
          final List<String> monthlyServices = [
            'Baby Care Taker',
            'Cook',
            'Driver',
            'Gardener',
            'Maid',
            'Security Guard',
          ];

          if (!monthlyServices.contains(service)) {
            workerServices.add(service);
            print('Found on-demand service in workers: $service');
          }
        }
      }

      // Add worker services that aren't already in our list
      for (String serviceName in workerServices) {
        if (!services.any((service) => service['title'] == serviceName)) {
          print('Adding worker service to on-demand list: $serviceName');
          services.add({
            'id':
                'worker_service_${serviceName.toLowerCase().replaceAll(' ', '_')}',
            'title': serviceName,
            'description': _getServiceDescription(serviceName),
            'icon': _getServiceIcon(serviceName),
            'color': _getServiceColor(serviceName),
            'locations': _getDefaultLocations(),
            'isNegotiable': false,
          });
        }
      }

      // Sort services in ascending order by title
      services.sort(
          (a, b) => a['title'].toString().compareTo(b['title'].toString()));

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load services: $e';
        _isLoading = false;
      });
      print('Error fetching services: $e');
    }
  }

  List<String> _getDefaultLocations() {
    return [
      'Johar Town',
      'Model Town',
      'Faisal Town',
      'Gulberg',
      'Lake City',
      'Valencia Town',
      'DHA',
      'Bahria Town',
      'WAPDA Town',
      'Allama Iqbal Town',
    ];
  }

  static String _getServiceDescription(String title) {
    switch (title) {
      case 'Maid':
        return 'Professional cleaning & organizing services';
      case 'Gardener':
        return 'Expert garden maintenance & landscaping';
      case 'Handyman':
        return 'Home repairs & maintenance services';
      case 'Locksmith':
        return 'Lock installation & repair services';
      case 'Auto Mechanic':
        return 'Vehicle repair & maintenance services';
      case 'Chef':
        return 'Professional cooking & catering services';
      case 'Driver':
        return 'Professional driving services';
      case 'Security Guard':
        return 'Professional security services';
      default:
        return 'Professional on-demand services';
    }
  }

  static IconData _getServiceIcon(String title) {
    switch (title) {
      case 'Maid':
        return Icons.cleaning_services;
      case 'Gardener':
        return Icons.yard;
      case 'Handyman':
        return Icons.handyman;
      case 'Locksmith':
        return Icons.lock;
      case 'Auto Mechanic':
        return Icons.car_repair;
      case 'Chef':
        return Icons.restaurant;
      case 'Driver':
        return Icons.drive_eta;
      case 'Security Guard':
        return Icons.security;
      default:
        return Icons.work;
    }
  }

  static Color _getServiceColor(String title) {
    switch (title) {
      case 'Maid':
        return Colors.teal;
      case 'Gardener':
        return Colors.green;
      case 'Handyman':
        return Colors.orange;
      case 'Locksmith':
        return Colors.grey;
      case 'Auto Mechanic':
        return Colors.blue;
      case 'Chef':
        return Colors.orange;
      case 'Driver':
        return Colors.blue;
      case 'Security Guard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> services,
    Map<String, dynamic> filters,
  ) {
    return services.where((service) {
      bool matchesService =
          filters['service'] == null || service['title'] == filters['service'];
      bool matchesLocation = filters['location'] == null ||
          service['locations'].contains(filters['location']);

      return matchesService && matchesLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = widget.filters != null
        ? _applyFilters(_services, widget.filters!)
        : _services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('On Demand Services'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: filteredServices.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Text('No services found',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredServices.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceDetailPage(
                                        serviceName: service['title'],
                                        serviceIcon: service['icon'],
                                        serviceType: 'On Demand',
                                        isNegotiable:
                                            service['isNegotiable'] as bool? ??
                                                false,
                                        description: service['description'],
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: service['color']
                                              .withOpacity(0.13),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          service['icon'],
                                          color: service['color'],
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                              service['title'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
