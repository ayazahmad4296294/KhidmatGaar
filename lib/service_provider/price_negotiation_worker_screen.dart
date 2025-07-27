import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/negotiation.dart';
import '../services/negotiation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PriceNegotiationWorkerScreen extends StatefulWidget {
  final String negotiationId;
  final String customerName;

  const PriceNegotiationWorkerScreen({
    super.key,
    required this.negotiationId,
    required this.customerName,
  });

  @override
  State<PriceNegotiationWorkerScreen> createState() =>
      _PriceNegotiationWorkerScreenState();
}

class _PriceNegotiationWorkerScreenState
    extends State<PriceNegotiationWorkerScreen> {
  final NegotiationService _negotiationService = NegotiationService();
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  Map<String, dynamic> _marketRates = {};
  PriceNegotiation? _currentNegotiation;
  String _customerAddress = 'Loading...';
  String _customerFullAddress = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get negotiation details
      _currentNegotiation =
          await _negotiationService.getNegotiationById(widget.negotiationId);

      if (_currentNegotiation == null) {
        throw Exception('Negotiation not found');
      }

      // Load market rates
      _marketRates = await _negotiationService
          .getSuggestedPriceRange(_currentNegotiation!.serviceName);

      // Fetch customer address from booking
      await _fetchCustomerAddress(_currentNegotiation!.bookingId);
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

  Future<void> _fetchCustomerAddress(String bookingId) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data();
        if (bookingData != null) {
          String address = bookingData['address'] ?? '';
          String fullAddress = bookingData['fullAddress'] ?? '';

          // If address is empty, try to extract it from the user data
          if (address.isEmpty && bookingData.containsKey('userId')) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(bookingData['userId'])
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              if (userData.containsKey('address')) {
                address = userData['address'] ?? '';
              }
              if (userData.containsKey('fullAddress')) {
                fullAddress = userData['fullAddress'] ?? '';
              }
            }
          }

          if (mounted) {
            setState(() {
              _customerAddress =
                  address.isNotEmpty ? address : 'No address provided';
              _customerFullAddress =
                  fullAddress.isNotEmpty ? fullAddress : _customerAddress;
            });
          }

          // If the address is still not available, set up a listener to watch for changes
          if (address.isEmpty) {
            print(
                'Address not found initially - setting up listener for changes');
            _setupAddressChangeListener(bookingId);
          } else {
            print('Customer address fetched: $address');
            print('Customer full address: $fullAddress');
          }
        }
      }
    } catch (e) {
      print('Error fetching customer address: $e');
      if (mounted) {
        setState(() {
          _customerAddress = 'Address not available';
        });
      }
    }
  }

  // Set up a listener to watch for address changes in the booking
  void _setupAddressChangeListener(String bookingId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null) {
          final address = data['address'] ?? '';
          final fullAddress = data['fullAddress'] ?? '';

          if (address.isNotEmpty) {
            setState(() {
              _customerAddress = address;
              _customerFullAddress =
                  fullAddress.isNotEmpty ? fullAddress : address;
            });
            print('Address updated via listener: $address');
          }
        }
      }
    });
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

    if (_currentNegotiation != null &&
        amount < _currentNegotiation!.minAcceptablePrice) {
      _showErrorSnackBar('Your offer is below your minimum acceptable price');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _negotiationService.makeCounterOffer(
        negotiationId: widget.negotiationId,
        amount: amount,
        message: _messageController.text.trim(),
        by: 'worker',
      );

      _offerController.clear();
      _messageController.clear();

      // Refresh negotiation data
      _currentNegotiation =
          await _negotiationService.getNegotiationById(widget.negotiationId);
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
      await _negotiationService.acceptOffer(widget.negotiationId);

      // Get the booking ID from the negotiation
      String bookingId = _currentNegotiation!.bookingId;

      // Update the booking status to scheduled with the negotiated price and other details
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'confirmed',
        'price': _currentNegotiation!.currentOffer,
        'updatedAt': FieldValue.serverTimestamp(),
        'negotiated': true,
        'negotiationCompleted': true,
        'scheduledAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Offer accepted! Booking scheduled and ready to start.')),
      );

      // Return to worker dashboard with refresh flag and go to scheduled tab
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/worker-dashboard',
        (route) => false,
        arguments: {'refresh': true, 'tab': 'scheduled'},
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
      await _negotiationService.rejectOffer(widget.negotiationId);

      // Update the booking to indicate negotiation was rejected
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_currentNegotiation!.bookingId)
          .update({
        'negotiationRejected': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer rejected')),
      );

      // Return to worker dashboard with refresh flag
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/worker-dashboard',
        (route) => false,
        arguments: {'refresh': true, 'tab': 'pending'},
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
    return StreamBuilder<PriceNegotiation>(
      stream: _negotiationService.negotiationStream(widget.negotiationId),
      initialData: _currentNegotiation,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.purple));
        }

        final negotiation = snapshot.data!;
        _currentNegotiation = negotiation;

        if (negotiation.isAccepted) {
          return _buildNegotiationCompletedView('Negotiation Accepted!');
        }

        if (negotiation.isRejected) {
          return _buildNegotiationCompletedView('Negotiation Rejected');
        }

        return _buildActiveNegotiationView(negotiation);
      },
    );
  }

  Widget _buildActiveNegotiationView(PriceNegotiation negotiation) {
    final isMyTurn = negotiation.offerBy == 'customer';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Address Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _customerAddress,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        if (_customerFullAddress.isNotEmpty &&
                            _customerFullAddress != _customerAddress)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _customerFullAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Original Negotiation Card
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
                              'Offered by: ${negotiation.offerBy == 'customer' ? widget.customerName : 'You'}',
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
                          'Initial Price: PKR ${negotiation.initialPrice.toStringAsFixed(2)}',
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
                          'Price Range',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPriceBox(
                                'Your Min', negotiation.minAcceptablePrice),
                            _buildPriceBox('Initial', negotiation.initialPrice),
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
              ? _buildResponseButtons(negotiation)
              : const Center(
                  child: Text(
                    'Waiting for customer to respond...',
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

  Widget _buildResponseButtons(PriceNegotiation negotiation) {
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

  Widget _buildNegotiationCompletedView(String statusMessage) {
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
            statusMessage,
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferHistoryItem(NegotiationOffer offer) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isCustomer = offer.by == 'customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCustomer ? Colors.grey[100] : Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustomer ? Colors.grey[300]! : Colors.purple[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCustomer ? widget.customerName : 'You',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCustomer ? Colors.black87 : Colors.purple,
                ),
              ),
              Text(
                'PKR ${offer.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCustomer ? Colors.black87 : Colors.purple,
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

  double _clampValue(double value, double min, double max) {
    if (min >= max) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
