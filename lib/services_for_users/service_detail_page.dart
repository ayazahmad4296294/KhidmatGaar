// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'worker_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/booking_service.dart';
import '../services/worker_service.dart';
import '../app_screens/home_page.dart';
import '../chat/chat_screen.dart';
import 'price_negotiation_screen.dart';
import 'worker_detail_page.dart';
import '../chat/start_chat_button.dart';
import '../services/chat_service.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceName;
  final IconData serviceIcon;
  final String serviceType;
  final bool isNegotiable;
  final String? description;

  const ServiceDetailPage({
    super.key,
    required this.serviceName,
    required this.serviceIcon,
    required this.serviceType,
    this.isNegotiable = false,
    this.description,
  });

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkerService _workerService = WorkerService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _workers = [];
  Map<String, dynamic>? _filters;

  @override
  void initState() {
    super.initState();
    // Don't load workers here, wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Safe to access ModalRoute.of(context) here
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('filters')) {
      _filters = args['filters'] as Map<String, dynamic>?;
    }

    // Check if we need to remove the test worker
    if (widget.serviceName == 'Driver') {
      _removeTestWorkerIfExists().then((_) {
        // Load workers after removing test worker
        _loadWorkers();
      });
    } else {
      // For other services, just load workers
      _loadWorkers();
    }
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading workers for service: ${widget.serviceName}');

      // Debug - Print all workers to check structure
      final allWorkers = await _firestore.collection('workers').limit(5).get();

      print('Total workers collection size: ${allWorkers.size}');
      for (var doc in allWorkers.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Worker document: ${doc.id}');
        print('Worker data: $data');
      }

      // Extract minRating from filters if available
      double? minRating;
      if (_filters != null && _filters!.containsKey('minRating')) {
        minRating = _filters!['minRating'] as double?;
        print('Filtering workers with minimum rating: $minRating');
      }

      print('Querying for workers with service: ${widget.serviceName}');

      // Query all workers (without status or service filter)
      final allWorkersQuery = await _firestore.collection('workers').get();

      print('Found ${allWorkersQuery.docs.length} total workers');

      // Manually filter by service name AND status (case insensitive)
      final List<QueryDocumentSnapshot> matchingWorkers =
          allWorkersQuery.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if service field exists and matches our service name
        bool serviceMatches = false;
        if (data['service'] != null) {
          final workerService = data['service'].toString().toLowerCase().trim();
          final targetService = widget.serviceName.toLowerCase().trim();
          serviceMatches = workerService == targetService;
        }

        // Check if status is approved (case insensitive)
        bool statusApproved = false;
        if (data['status'] != null) {
          final status = data['status'].toString().toLowerCase().trim();
          statusApproved = status == 'approved' || status == 'Approved';
        }

        if (serviceMatches && statusApproved) {
          print(
              'Found matching worker: ${data['firstName']} ${data['lastName']} (service: ${data['service']}, status: ${data['status']})');
        }

        return serviceMatches && statusApproved;
      }).toList();

      print(
          'Found ${matchingWorkers.length} workers for ${widget.serviceName} after manual filtering');

      var workers = matchingWorkers.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final isOnline = data['isOnline'] ?? false;

        return {
          'id': doc.id,
          'name': fullName.isNotEmpty
              ? fullName
              : 'Worker ${doc.id.substring(0, 4)}',
          'experience': data['expirence']?.toString() ??
              data['experience']?.toString() ??
              'Not specified',
          'location': data['location']?.toString() ?? 'Not specified',
          'registrationDate': data['registrationDate'] != null
              ? (data['registrationDate'] as Timestamp).toDate()
              : DateTime.now(),
          'service': data['service']?.toString() ?? '',
          'phone': data['phone']?.toString() ?? '',
          'userId': data['userId']?.toString() ?? '',
          'cnic': data['cnic']?.toString() ?? '',
          'isOnline': isOnline, // Add online status
          // Default values for UI if not present in database
          'rating': (data['rating'] as num?)?.toDouble() ?? 0,
          'completedJobs': (data['completedJobs'] as num?)?.toInt() ?? 0,
          'description':
              'Professional ${widget.serviceName} service provider with ${data['expirence']?.toString() ?? data['experience']?.toString() ?? 'relevant'} experience.',
        };
      }).toList();

      // Filter for online workers only
      workers = workers.where((worker) => worker['isOnline'] == true).toList();
      print('After online filter, found ${workers.length} workers');

      // Apply additional filter for worker rating if needed
      if (minRating != null && minRating > 0) {
        workers = workers.where((worker) {
          double workerRating = (worker['rating'] as double?) ?? 0.0;
          return workerRating >= minRating!;
        }).toList();
        print('After rating filter, found ${workers.length} workers');
      }

      // Filter by location if specified in the filters
      if (_filters != null && _filters!.containsKey('location')) {
        final location = _filters!['location'] as String?;
        if (location != null) {
          workers = workers.where((worker) {
            return worker['location'] == location;
          }).toList();
          print('After location filter, found ${workers.length} workers');
        }
      }

      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a method to remove the test worker if it exists
  Future<void> _removeTestWorkerIfExists() async {
    try {
      // Look for the test worker
      final testWorkerQuery = await _firestore
          .collection('workers')
          .where('firstName', isEqualTo: 'Test')
          .where('lastName', isEqualTo: 'Driver')
          .get();

      // If found, delete it
      for (var doc in testWorkerQuery.docs) {
        print('Removing test worker: ${doc.id}');
        await _firestore.collection('workers').doc(doc.id).delete();
        print('Test worker removed successfully');
      }
    } catch (e) {
      print('Error removing test worker: $e');
    }
  }

  void _showDescriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Service Description'),
          content: Text(
              widget.description ?? _getServiceDescription(widget.serviceName)),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'Maid':
        return 'Professional house cleaning and maintenance services. Includes dusting, mopping, laundry, and organizing. Trained staff to keep your home spotless and well-maintained.';
      case 'Cook':
        return 'Expert cooking services for all your culinary needs. Specializes in local and international cuisines. Can prepare healthy, customized meals according to your preferences.';
      case 'Driver':
        return 'Professional and experienced drivers for safe transportation. Well-versed with local routes and traffic regulations. Punctual and reliable service for all your travel needs.';
      case 'Security Guard':
        return 'Trained security personnel for your safety and protection. 24/7 surveillance and monitoring services. Background-verified guards with proper security training.';
      case 'Baby Care Taker':
        return 'Experienced caregivers for your child\'s wellbeing. Trained in child care, first aid, and emergency response. Provides educational activities and proper care for children.';
      case 'Gardener':
        return 'Expert gardening and landscaping services. Maintains garden health, plant care, and lawn maintenance. Creates and maintains beautiful outdoor spaces.';
      case 'Handyman':
        return 'General maintenance and repair services for your home. Skilled in basic plumbing, electrical work, and carpentry. Quick solutions for household maintenance issues.';
      case 'Locksmith':
        return 'Professional lock installation and repair services. Expert in handling all types of locks and security systems. Emergency services available when needed.';
      case 'Auto Mechanic':
        return 'Skilled automotive repair and maintenance services. Experienced in handling various vehicle types and models. Provides regular maintenance and emergency repair services.';
      case 'Chef':
        return 'Professional culinary experts for special occasions. Creates customized menus for events and parties. Experienced in multiple cuisines and dietary requirements.';
      default:
        return 'Professional $service services available for your needs. Our verified workers ensure quality service delivery.';
    }
  }

  Widget _buildServiceForm(BuildContext context) {
    DateTime? selectedDateTime;
    final BookingService _bookingService = BookingService();

    // Function to save booking to database
    Future<void> _createBooking(
        Map<String, dynamic> worker, DateTime bookingTime) async {
      print(
          "DEBUG: Creating booking for worker: ${worker['name']} at time: $bookingTime");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to schedule a booking')),
        );
        return;
      }

      // Set default price based on service type
      double servicePrice = 0.0;
      switch (widget.serviceName) {
        case 'Maid':
          servicePrice = 2500.0;
          break;
        case 'Cook':
          servicePrice = 3000.0;
          break;
        case 'Driver':
          servicePrice = 2800.0;
          break;
        case 'Security Guard':
          servicePrice = 3500.0;
          break;
        case 'Baby Care Taker':
          servicePrice = 4000.0;
          break;
        case 'Gardener':
          servicePrice = 2200.0;
          break;
        case 'Handyman':
          servicePrice = 3200.0;
          break;
        case 'Locksmith':
          servicePrice = 4500.0;
          break;
        case 'Auto Mechanic':
          servicePrice = 3800.0;
          break;
        case 'Chef':
          servicePrice = 5000.0;
          break;
        default:
          servicePrice = 3000.0;
      }

      try {
        // Create booking using BookingService
        print("DEBUG: Scheduling booking via BookingService");
        String bookingId = await _bookingService.scheduleBooking(
          workerId: worker['id'],
          workerName: worker['name'],
          serviceType: widget.serviceName,
          address: 'Default Address', // You might want to get this from user
          scheduledDateTime: bookingTime,
          price: servicePrice,
          notes: 'Scheduled from service detail page',
        );

        print("DEBUG: Booking created successfully with ID: $bookingId");

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Booking Confirmed'),
            content: Text(
              'Your service with ${worker['name']} is scheduled for ${bookingTime.toLocal().toString().substring(0, 16)}.\n\n'
              'You can track the status of your booking in the Bookings tab.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to home page's bookings tab
                  HomePage.navigateToBookingsTab(context);
                },
                child: const Text(
                  'Go to Bookings',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        print("DEBUG: Error creating booking: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    }

    void _selectDateTime(Map<String, dynamic> worker) async {
      DateTime now = DateTime.now();
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );

      if (pickedDate != null) {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Create the booking in Firestore
          await _createBooking(worker, selectedDateTime!);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Negotiation Card
        if (widget.isNegotiable) ...[
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Negotiation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a service provider below and visit their profile to negotiate price. Bargain in real-time based on market rates.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ],

        // Service Providers Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Service Providers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
            if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                width: 20,
                height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.purple),
                    ),
                  ),
                IconButton(
                  onPressed: _isLoading ? null : _loadWorkers,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh list',
                  color: Colors.purple,
                ),
              ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Colors.purple),
                ),
              )
            : _workers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No service providers available at the moment',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _workers.map((worker) {
                      return _buildWorkerCard(context, worker, _selectDateTime);
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, Map<String, dynamic> worker,
      Function(Map<String, dynamic>) onSchedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.purple.withOpacity(0.2),
                  child: Text(
                    worker['name'].toString().isNotEmpty
                        ? worker['name']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase()
                        : 'W',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Add online status indicator
                          if (worker['isOnline'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      color: Colors.white, size: 8),
                                  SizedBox(width: 4),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkerDetailPage(
                                    worker: worker,
                                    serviceName: widget.serviceName,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('View Profile'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                              ' ${(worker['rating'] as num? ?? 0.0).toStringAsFixed(1)} • ${worker['completedJobs']} jobs'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Experience: ${worker['experience']}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _startChat(context, worker),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _startPriceNegotiation(worker),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Negotiate'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onSchedule(worker),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Schedule'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat(
      BuildContext context, Map<String, dynamic> worker) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to start a chat')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.purple)),
      );

      final chatService = ChatService();
      final conversationId = await chatService.createOrGetConversation(
        customerId: user.uid,
        customerName: user.displayName ?? 'Customer',
        workerId: worker['id'],
        workerName: worker['name'],
      );

      navigator.pop(); // Close loading dialog

      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherPersonName: worker['name'],
            otherPersonId: worker['id'],
          ),
        ),
      );
    } catch (e) {
      navigator.pop(); // Close loading dialog
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  void _startPriceNegotiation(Map<String, dynamic> worker) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to negotiate price')),
      );
      return;
    }

    // Create a unique booking ID for this negotiation
    final bookingId = _firestore.collection('bookings').doc().id;

    // Determine initial price based on service type
    double initialPrice = 3000.0; // Default price
    switch (widget.serviceName) {
      case 'Maid':
        initialPrice = 2500.0;
        break;
      case 'Cook':
        initialPrice = 3000.0;
        break;
      case 'Driver':
        initialPrice = 2800.0;
        break;
      case 'Security Guard':
        initialPrice = 3500.0;
        break;
      case 'Baby Care Taker':
        initialPrice = 4000.0;
        break;
      case 'Gardener':
        initialPrice = 2200.0;
        break;
      case 'Handyman':
        initialPrice = 3200.0;
        break;
      case 'Locksmith':
        initialPrice = 4500.0;
        break;
      case 'Auto Mechanic':
        initialPrice = 3800.0;
        break;
      case 'Chef':
        initialPrice = 5000.0;
        break;
    }

    // Open negotiation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceNegotiationScreen(
          workerId: worker['id'],
          workerName: worker['name'],
          serviceName: widget.serviceName,
          bookingId: bookingId,
          initialPrice: initialPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDescriptionDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildServiceForm(context),
          ],
        ),
      ),
    );
  }
}
