import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../services/loyalty_service.dart';
import 'booking_detail_screen.dart';
import '../app_screens/home_page.dart';
import '../services/location_picker.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String serviceType;
  final double servicePrice;

  const ServiceBookingScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
    required this.serviceType,
    required this.servicePrice,
  }) : super(key: key);

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final BookingService _bookingService = BookingService();
  final LoyaltyService _loyaltyService = LoyaltyService();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(
    hour: DateTime.now().hour + 1,
    minute: 0,
  );

  bool _isLoading = false;
  int _availablePoints = 0;
  int _pointsToRedeem = 0;
  double _finalPrice = 0;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.servicePrice;
    _loadLoyaltyPoints();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLoyaltyPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _loyaltyService.getUserPointsSummary();
      setState(() {
        _availablePoints = summary.availablePoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading loyalty points: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _getDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  void _updateRedeemPoints(int points) {
    setState(() {
      _pointsToRedeem = points;
      // Calculate discount (500 points = PKR 100)
      _discountAmount = (points / 500) * 100;
      _finalPrice = widget.servicePrice - _discountAmount;

      // Ensure price doesn't go below 0
      if (_finalPrice < 0) {
        _finalPrice = 0;
      }
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("DEBUG: Starting booking creation process");
      print("DEBUG: Worker ID: ${widget.workerId}");
      print("DEBUG: Worker Name: ${widget.workerName}");
      print("DEBUG: Service Type: ${widget.serviceType}");
      print("DEBUG: Address: ${_addressController.text}");
      print("DEBUG: Scheduled Date/Time: ${_getDateTime()}");
      print("DEBUG: Price: $_finalPrice");

      // Create the booking
      String bookingId = await _bookingService.scheduleBooking(
        workerId: widget.workerId,
        workerName: widget.workerName,
        serviceType: widget.serviceType,
        address: _addressController.text,
        scheduledDateTime: _getDateTime(),
        price: _finalPrice,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      print("DEBUG: Booking created with ID: $bookingId");

      // Verify booking was created by fetching it back
      final createdBooking = await _bookingService.getBookingById(bookingId);
      if (createdBooking != null) {
        print("DEBUG: Booking verification successful!");
        print("DEBUG: Verified booking details:");
        print("DEBUG: - User ID: ${createdBooking.userId}");
        print("DEBUG: - Worker ID: ${createdBooking.workerId}");
        print("DEBUG: - Service: ${createdBooking.serviceType}");
        print("DEBUG: - Status: ${createdBooking.status}");
        print("DEBUG: - Scheduled: ${createdBooking.scheduledDateTime}");
      } else {
        print(
            "DEBUG: WARNING! Booking verification failed - could not retrieve booking after creation");
      }

      // Apply loyalty points if any
      if (_pointsToRedeem > 0) {
        print("DEBUG: Applying loyalty points: $_pointsToRedeem");
        await _bookingService.applyLoyaltyPointsDiscount(
          bookingId,
          _pointsToRedeem,
        );
        print("DEBUG: Loyalty points applied successfully");
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: const Text(
            'Your service has been successfully scheduled. You can track the status of your booking in the Bookings tab on the bottom navigation bar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to home page's bookings tab
                HomePage.navigateToBookingsTab(context);
              },
              child: const Text(
                'Go to Bookings',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Go directly to the booking details page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(
                      bookingId: bookingId,
                      availablePoints: _availablePoints - _pointsToRedeem,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text(
                'View Booking Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print("DEBUG: ERROR creating booking: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Service'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildServiceInfoCard(),
                      const SizedBox(height: 24),
                      _buildDateTimeSection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      if (_availablePoints >= 500) _buildLoyaltyPointsSection(),
                      if (_availablePoints >= 500) const SizedBox(height: 24),
                      _buildPriceSummary(),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildServiceInfoCard() {
    return Card(
      elevation: 3,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_repair_service,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provider: ${widget.workerName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR ${widget.servicePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.purple),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.purple),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Complete Address',
                prefixIcon: Icon(Icons.location_on, color: Colors.purple),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openLocationPicker,
                    icon: const Icon(Icons.map),
                    label: const Text('Select on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: Icon(Icons.note, color: Colors.purple),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    setState(() {
      _addressController.text = locationProvider.currentAddress;
      _isLoading = false;
    });
  }

  void _openLocationPicker() {
    try {
      print('Attempting to open location picker');
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => LocationPicker(
            onLocationSelected: (latitude, longitude, address) {
              print('Location selected: $latitude, $longitude, $address');
              setState(() {
                _addressController.text = address;
              });
            },
          ),
        ),
      )
          .catchError((error) {
        print('Error opening LocationPicker: $error');
        // Use the fallback dialog if the map fails to load
        _showFallbackLocationDialog();
      });
    } catch (e) {
      print('Exception in _openLocationPicker: $e');
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
      },
    );
  }

  Widget _buildLoyaltyPointsSection() {
    // Calculate the maximum points the user can redeem
    // Either all available points, or based on price (can't discount more than the actual price)
    final maxPointsBasedOnPrice = (widget.servicePrice / 100 * 500).floor();
    final maxPoints = (_availablePoints < maxPointsBasedOnPrice)
        ? _availablePoints
        : maxPointsBasedOnPrice;

    // Make sure maxPoints is a multiple of 500
    final adjustedMaxPoints = (maxPoints ~/ 500) * 500;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Loyalty Points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Available: $_availablePoints',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your loyalty points to get a discount on this booking.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '500 points = PKR 100 discount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Points to redeem:'),
                const Spacer(),
                DropdownButton<int>(
                  value: _pointsToRedeem,
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('0 points'),
                    ),
                    for (int i = 500; i <= adjustedMaxPoints; i += 500)
                      DropdownMenuItem(
                        value: i,
                        child: Text('$i points'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateRedeemPoints(value);
                    }
                  },
                ),
              ],
            ),
            if (_pointsToRedeem > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_pointsToRedeem points will be redeemed for a discount of PKR ${_discountAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      elevation: 3,
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Price'),
                Text(
                  'PKR ${widget.servicePrice.toStringAsFixed(2)}',
                ),
              ],
            ),
            if (_discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loyalty Discount'),
                  Text(
                    '- PKR ${_discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'PKR ${_finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'CASH ON DELIVERY',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will earn ${_loyaltyService.calculateBookingPoints(_finalPrice)} loyalty points after the service is completed!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
