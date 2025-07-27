// ignore_for_file: unused_field, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_detail_page.dart';

class MonthlyHiringService extends StatefulWidget {
  final Map<String, dynamic>? filters;

  const MonthlyHiringService({super.key, this.filters});

  @override
  State<MonthlyHiringService> createState() => _MonthlyHiringServiceState();
}

class _MonthlyHiringServiceState extends State<MonthlyHiringService> {
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

      // First try to get services from Monthly_Services collection
      final QuerySnapshot snapshot =
          await _firestore.collection('Monthly_Services').get();

      List<Map<String, dynamic>> services = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Service from Monthly_Services: ${data['service_name']}');
        return {
          'id': doc.id,
          'title': data['service_name'] ?? 'Unknown Service',
          'description': data['service_description'] ??
              _getServiceDescription(data['service_name'] ?? ''),
          'icon': _getServiceIcon(data['service_name'] ?? ''),
          'color': _getServiceColor(data['service_name'] ?? ''),
          'locations': _getDefaultLocations(),
        };
      }).toList();

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

  static String _getServiceDescription(String title) {
    switch (title) {
      case 'Maid':
        return 'Full-time house cleaning & management';
      case 'Cook':
        return 'Daily meal preparation & cooking';
      case 'Driver':
        return 'Full-time personal driver services';
      case 'Security Guard':
        return '24/7 security & protection services';
      case 'Gardener':
        return 'Full-time garden care & maintenance';
      case 'Baby Care Taker':
        return 'Professional childcare services';
      default:
        return 'Professional monthly services';
    }
  }

  static IconData _getServiceIcon(String title) {
    switch (title) {
      case 'Maid':
        return Icons.cleaning_services;
      case 'Cook':
        return Icons.restaurant;
      case 'Driver':
        return Icons.drive_eta;
      case 'Security Guard':
        return Icons.security;
      case 'Gardener':
        return Icons.grass;
      case 'Baby Care Taker':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }

  static Color _getServiceColor(String title) {
    switch (title) {
      case 'Maid':
        return Colors.teal;
      case 'Cook':
        return Colors.orange;
      case 'Driver':
        return Colors.blue;
      case 'Security Guard':
        return Colors.red;
      case 'Gardener':
        return Colors.green;
      case 'Baby Care Taker':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = widget.filters != null
        ? _applyFilters(_services, widget.filters!)
        : _services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Hiring Services'),
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
                                        serviceType: 'Monthly',
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
