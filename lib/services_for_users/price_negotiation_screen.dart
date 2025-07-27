// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/negotiation.dart';
import '../services/negotiation_service.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/location_picker.dart';

class PriceNegotiationScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String serviceName;
  final String bookingId;
  final double initialPrice;

  const PriceNegotiationScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.serviceName,
    required this.bookingId,
    required this.initialPrice,
  });

  @override
  State<PriceNegotiationScreen> createState() => _PriceNegotiationScreenState();
}

class _PriceNegotiationScreenState extends State<PriceNegotiationScreen> {
  final NegotiationService _negotiationService = NegotiationService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late double _maxAcceptablePrice;
  String _negotiationId = '';
  bool _isLoading = true;
  bool _isNegotiationStarted = false;
  Map<String, dynamic> _marketRates = {};
  bool _isEditingAddress = false;

  PriceNegotiation? _currentNegotiation;

  @override
  void initState() {
    super.initState();
    _maxAcceptablePrice =
        widget.initialPrice * 1.2; // Default: 20% above initial
    _loadData();
    // Initialize address controller with current address from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      _addressController.text = locationProvider.currentAddress;
    });
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load market rates
      _marketRates =
          await _negotiationService.getSuggestedPriceRange(widget.serviceName);

      // Check if negotiation already exists for this booking
      final querySnapshot = await FirebaseFirestore.instance
          .collection('negotiations')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _negotiationId = doc.id;
        _currentNegotiation = PriceNegotiation.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _isNegotiationStarted = true;
      }
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateServiceAddress() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.updateAddress(_addressController.text);
    setState(() {
      _isEditingAddress = false;
    });
  }

  void _showAddressSelectionBottomSheet() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (locationProvider.savedAddresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No saved addresses found'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: locationProvider.savedAddresses.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(locationProvider.savedAddresses[index]),
                        onTap: () {
                          _addressController.text =
                              locationProvider.savedAddresses[index];
                          _updateServiceAddress();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() {
                      _isLoading = true;
                    });
                    await locationProvider.getCurrentLocation();
                    _addressController.text = locationProvider.currentAddress;
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Select on Map'),
                  onPressed: () {
                    Navigator.pop(context);
                    _openLocationPicker();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLocationPicker() {
    try {
      print('PriceNegotiationScreen: Attempting to open location picker');
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => LocationPicker(
            onLocationSelected: (latitude, longitude, address) {
              print(
                  'PriceNegotiationScreen: Location selected: $latitude, $longitude, $address');
              setState(() {
                _addressController.text = address;
              });

              // Update location provider
              final locationProvider =
                  Provider.of<LocationProvider>(context, listen: false);
              locationProvider.updateAddress(address, fullAddress: address);
            },
          ),
        ),
      )
          .catchError((error) {
        print('PriceNegotiationScreen: Error opening LocationPicker: $error');
        // Use the fallback dialog if the map fails to load
        _showFallbackLocationDialog();
      });
    } catch (e) {
      print('PriceNegotiationScreen: Exception in _openLocationPicker: $e');
      // Use the fallback dialog if there's an exception
      _showFallbackLocationDialog();
    }
  }

  void _showFallbackLocationDialog() {
    LocationPicker.showFallbackLocationDialog(
      context,
      (latitude, longitude, address) {
        setState(() {
          _addressController.text = address;
        });

        // Update location provider
        final locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        locationProvider.updateAddress(address, fullAddress: address);
      },
    );
  }

  Future<void> _startNegotiation() async {
    if (_maxAcceptablePrice <= 0) {
      _showErrorSnackBar('Please set a valid maximum price');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current address from the location provider
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      // Make sure we have the latest address
      final currentAddress = _addressController.text;

      // Check if the booking exists first
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      // If booking doesn't exist, create a temporary placeholder booking
      if (!bookingDoc.exists) {
        print('Booking not found, creating a placeholder: ${widget.bookingId}');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Create a placeholder booking record
        final booking = {
          'userId': user.uid,
          'workerId': widget.workerId,
          'workerName': widget.workerName,
          'serviceType': widget.serviceName,
          'address': currentAddress,
          'fullAddress': locationProvider.fullAddress,
          'scheduledDateTime': Timestamp.fromDate(DateTime.now()),
          'status': 'confirmed',
          'price': widget.initialPrice,
          'discountAmount': 0.0,
          'notes': 'Created for negotiation',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'isPaid': false,
          'paymentMethod': 'cash',
          'isReviewed': false,
          'isTemporary': true, // Flag to indicate this is a placeholder
        };

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .set(booking);

        print('Created placeholder booking: ${widget.bookingId}');
      } else {
        // Booking exists, just update the address
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'address': currentAddress,
          'fullAddress': locationProvider.fullAddress,
        });
      }

      print('Starting negotiation for booking: ${widget.bookingId}');
      _negotiationId = await _negotiationService.startNegotiation(
        bookingId: widget.bookingId,
        workerId: widget.workerId,
        serviceName: widget.serviceName,
        initialPrice: widget.initialPrice,
        minAcceptablePrice:
            widget.initialPrice * 0.8, // Worker's minimum (example)
        maxAcceptablePrice: _maxAcceptablePrice, // Customer's maximum
      );

      // Get the negotiation details
      _currentNegotiation =
          await _negotiationService.getNegotiationById(_negotiationId);
      _isNegotiationStarted = true;

      // Send notification to worker about the negotiation
      // This will ensure the worker is alerted to check their pending tab
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user's display name or use user ID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String customerName = 'Customer';
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            customerName =
                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                    .trim();
            if (customerName.isEmpty) customerName = 'Customer';
          }
        }

        try {
          // Use the specialized negotiation request notification
          await _notificationService.sendNegotiationRequestNotification(
            workerId: widget.workerId,
            negotiationId: _negotiationId,
            customerName: customerName,
            serviceType: widget.serviceName,
            proposedPrice: widget.initialPrice,
          );
          print('Sent negotiation notification to worker: ${_negotiationId}');
        } catch (e) {
          // Fallback to basic notification if the specialized one fails
          await _notificationService.sendBookingUpdateNotification(
            userId: widget.workerId,
            bookingId: widget.bookingId,
            serviceType: widget.serviceName,
            status: 'price negotiation started',
          );
          print('Sent basic notification to worker: ${_negotiationId}');
        }
      }
    } catch (e) {
      print('Error in _startNegotiation: $e');
      _showErrorSnackBar('Error starting negotiation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeCounterOffer() async {
    final offerText = _offerController.text.trim();
    if (offerText.isEmpty) {
      _showErrorSnackBar('Please enter an offer amount');
      return;
    }

    double amount;
    try {
      amount = double.parse(offerText);
    } catch (e) {
      _showErrorSnackBar('Please enter a valid number');
      return;
    }

    if (amount <= 0) {
      _showErrorSnackBar('Please enter a positive amount');
      return;
    }

    if (amount > _maxAcceptablePrice) {
      _showErrorSnackBar('Your offer exceeds your maximum acceptable price');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _negotiationService.makeCounterOffer(
        negotiationId: _negotiationId,
        amount: amount,
        message: _messageController.text.trim(),
        by: 'customer',
      );

      _offerController.clear();
      _messageController.clear();

      // Refresh negotiation data
      _currentNegotiation =
          await _negotiationService.getNegotiationById(_negotiationId);
    } catch (e) {
      _showErrorSnackBar('Error making offer: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptOffer() async {
    if (_currentNegotiation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _negotiationService.acceptOffer(_negotiationId);

      // Get the current address from the location provider
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      // Make sure we have the latest address from the address controller
      final currentAddress = _addressController.text;

      // Update the booking status to pending with the negotiated price and address
      // For customer view, the status remains 'pending' after accepting the offer
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'pending',
        'price': _currentNegotiation!.currentOffer,
        'updatedAt': FieldValue.serverTimestamp(),
        'address': currentAddress,
        'fullAddress': locationProvider.fullAddress,
        'negotiated': true,
        'negotiationCompleted': true,
        'pendingAt': FieldValue.serverTimestamp(),
      });

      // Return result to the previous screen
      final result = {
        'accepted': true,
        'finalPrice': _currentNegotiation!.currentOffer,
        'address': currentAddress,
        'fullAddress': locationProvider.fullAddress,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Offer accepted! Booking pending for worker to start service.')),
      );

      // Navigate to bookings tab directly
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
        arguments: {'tab': 'bookings'},
      );
    } catch (e) {
      _showErrorSnackBar('Error accepting offer: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectOffer() async {
    if (_currentNegotiation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _negotiationService.rejectOffer(_negotiationId);

      // Update the booking to indicate negotiation was rejected
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'negotiationRejected': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer rejected')),
      );

      // Navigate to home page with bookings tab
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
        arguments: {'tab': 'bookings'},
      );
    } catch (e) {
      _showErrorSnackBar('Error rejecting offer: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Negotiation'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return _isNegotiationStarted
        ? StreamBuilder<PriceNegotiation>(
            stream: _negotiationService.negotiationStream(_negotiationId),
            initialData: _currentNegotiation,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.purple));
              }

              final negotiation = snapshot.data!;

              if (negotiation.isAccepted) {
                return _buildNegotiationCompletedView('Negotiation Accepted!');
              }

              if (negotiation.isRejected) {
                return _buildNegotiationCompletedView('Negotiation Rejected');
              }

              return _buildActiveNegotiationView(negotiation);
            },
          )
        : _buildStartNegotiationView();
  }

  Widget _buildActiveNegotiationView(PriceNegotiation negotiation) {
    final isMyTurn = negotiation.offerBy == 'worker';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Address Section Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Service Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_isEditingAddress)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.list),
                                    onPressed: _showAddressSelectionBottomSheet,
                                    tooltip: 'Select from saved addresses',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _isEditingAddress = true;
                                      });
                                    },
                                    tooltip: 'Edit address',
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isEditingAddress
                            ? Column(
                                children: [
                                  TextField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your address',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditingAddress = false;
                                            // Reset to original value
                                            final locationProvider =
                                                Provider.of<LocationProvider>(
                                                    context,
                                                    listen: false);
                                            _addressController.text =
                                                locationProvider.currentAddress;
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _updateServiceAddress,
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _addressController.text,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current Offer Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Offer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PKR ${negotiation.currentOffer.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              'Offered by: ${negotiation.offerBy == 'worker' ? widget.workerName : 'You'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Service details
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Service: ${negotiation.serviceName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Initial Price: PKR ${widget.initialPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Service Provider: ${widget.workerName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Negotiation Started: ${DateFormat('MMM d, yyyy').format(negotiation.createdAt)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Offer history
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Negotiation History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...negotiation.offerHistory.reversed
                            .map((offer) => _buildOfferHistoryItem(offer)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Price range guidance
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Price Range',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPriceBox('Initial', widget.initialPrice),
                            _buildPriceBox('Your Max', _maxAcceptablePrice),
                          ],
                        ),
                        if (_marketRates.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Market Average',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(builder: (context) {
                            bool canShowSlider = _marketRates['minMarketRate'] <
                                    _marketRates['maxMarketRate'] &&
                                _marketRates['maxMarketRate'] > 0;

                            if (canShowSlider) {
                              return Column(
                                children: [
                                  Slider(
                                    value: _clampValue(
                                      negotiation.currentOffer,
                                      _marketRates['minMarketRate'],
                                      _marketRates['maxMarketRate'],
                                    ),
                                    min: _marketRates['minMarketRate'],
                                    max: _marketRates['maxMarketRate'],
                                    divisions: 20,
                                    onChanged: null,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          'PKR ${_marketRates['minMarketRate'].toStringAsFixed(2)}'),
                                      Text(
                                          'PKR ${_marketRates['maxMarketRate'].toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return const Text(
                                'Market rate data is not available for this service.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              );
                            }
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: isMyTurn
              ? _buildOfferResponseSection()
              : const Center(
                  child: Text(
                    'Waiting for service provider to respond...',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  double _clampValue(double value, double min, double max) {
    if (min >= max) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  Widget _buildPriceBox(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            'PKR ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferHistoryItem(NegotiationOffer offer) {
    final isCustomer = offer.by == 'customer';
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCustomer ? Colors.purple[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustomer ? Colors.purple[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCustomer ? 'You' : widget.workerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCustomer ? Colors.purple : Colors.black87,
                ),
              ),
              Text(
                'PKR ${offer.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCustomer ? Colors.purple : Colors.black87,
                ),
              ),
            ],
          ),
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(offer.message!),
          ],
          const SizedBox(height: 4),
          Text(
            dateFormat.format(offer.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _acceptOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept Offer',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _rejectOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Reject Offer',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Make Counter Offer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _offerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your counter offer',
                  prefixText: 'PKR ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Add a message (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _makeCounterOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Send Counter Offer',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStartNegotiationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address Section Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEditingAddress)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list),
                              onPressed: _showAddressSelectionBottomSheet,
                              tooltip: 'Select from saved addresses',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _isEditingAddress = true;
                                });
                              },
                              tooltip: 'Edit address',
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditingAddress
                      ? Column(
                          children: [
                            TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your address',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingAddress = false;
                                      // Reset to original value
                                      final locationProvider =
                                          Provider.of<LocationProvider>(context,
                                              listen: false);
                                      _addressController.text =
                                          locationProvider.currentAddress;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _updateServiceAddress,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _addressController.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Service Details Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Service: ${widget.serviceName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service Provider: ${widget.workerName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initial Price: PKR ${widget.initialPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Market rates card
          if (_marketRates.isNotEmpty)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Market Price Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _buildPriceBox(
                            'Minimum', _marketRates['minMarketRate'] ?? 0.0),
                        _buildPriceBox(
                            'Average', _marketRates['avgMarketRate'] ?? 0.0),
                        _buildPriceBox(
                            'Maximum', _marketRates['maxMarketRate'] ?? 0.0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Max acceptable price
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Your Maximum Acceptable Price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current Maximum: PKR ${_maxAcceptablePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _maxAcceptablePrice,
                    min: widget.initialPrice * 0.8,
                    max: widget.initialPrice * 1.5,
                    divisions: 20,
                    label: 'PKR ${_maxAcceptablePrice.toStringAsFixed(2)}',
                    activeColor: Colors.purple,
                    onChanged: (value) {
                      setState(() {
                        _maxAcceptablePrice = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _startNegotiation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Start Negotiation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationCompletedView(String message) {
    if (_currentNegotiation == null) {
      return const Center(child: Text('Negotiation data not available'));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Final Price: PKR ${_currentNegotiation!.currentOffer.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Return to home page with bookings tab
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
                arguments: {'tab': 'bookings'},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: const Text(
              'Back to Bookings',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
