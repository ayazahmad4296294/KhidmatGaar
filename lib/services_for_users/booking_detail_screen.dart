import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../app_screens/review_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final int availablePoints;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
    required this.availablePoints,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _bookingService.cancelBooking(widget.bookingId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Booking cancelled successfully')),
                );
                _loadBooking();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling booking: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    final DateTime initialDate = _booking!.scheduledDateTime;
    DateTime selectedDate = initialDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(initialDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reschedule Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  await _bookingService.rescheduleBooking(
                    widget.bookingId,
                    newDateTime,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking rescheduled successfully'),
                    ),
                  );
                  _loadBooking();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rescheduling booking: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text(
                'Reschedule',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemPointsDialog() {
    if (widget.availablePoints < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 500 points to apply a discount'),
        ),
      );
      return;
    }

    final TextEditingController pointsController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Loyalty Points'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Points: ${widget.availablePoints}'),
              Text(
                'Booking Total: PKR ${_booking!.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points to Redeem',
                  hintText: 'Enter points (500 minimum)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points to redeem';
                  }

                  final points = int.tryParse(value);
                  if (points == null) {
                    return 'Please enter a valid number';
                  }

                  if (points < 500) {
                    return 'Minimum 500 points required';
                  }

                  if (points > widget.availablePoints) {
                    return 'You don\'t have enough points';
                  }

                  // Points must be in multiples of 500
                  if (points % 500 != 0) {
                    return 'Points must be in multiples of 500';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Exchange your loyalty points for a discount on this booking.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                '500 points = PKR 100 discount',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final pointsToRedeem = int.parse(pointsController.text);
                Navigator.pop(context);

                try {
                  await _bookingService.applyLoyaltyPointsDiscount(
                    widget.bookingId,
                    pointsToRedeem,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully applied $pointsToRedeem points for discount',
                      ),
                    ),
                  );
                  _loadBooking();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error applying points: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text(
              'Apply Points',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 16),
                      _buildServiceDetails(),
                      const SizedBox(height: 16),
                      _buildScheduleDetails(),
                      const SizedBox(height: 16),
                      _buildPriceDetails(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusHeader() {
    final booking = _booking!;
    final statusColor = booking.statusEnum.getStatusColor();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(booking.statusEnum),
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.statusEnum.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(booking.statusEnum),
                    style: const TextStyle(
                      color: Colors.grey,
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

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.handyman;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rescheduled:
        return Icons.event_repeat;
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Your booking is awaiting confirmation';
      case BookingStatus.confirmed:
        return 'Your booking has been confirmed';
      case BookingStatus.inProgress:
        return 'Service is currently being provided';
      case BookingStatus.completed:
        return 'Service has been completed';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled';
      case BookingStatus.rescheduled:
        return 'Your booking has been rescheduled';
    }
  }

  Widget _buildServiceDetails() {
    final booking = _booking!;

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
            _buildInfoRow(
              Icons.home_repair_service,
              'Service Type',
              booking.serviceType,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.person,
              'Service Provider',
              booking.workerName,
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note,
                'Notes',
                booking.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDetails() {
    final booking = _booking!;
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              dateFormat.format(booking.scheduledDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              timeFormat.format(booking.scheduledDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              booking.address,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    final booking = _booking!;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
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
                  'PKR ${(booking.price + (booking.discountAmount ?? 0)).toStringAsFixed(2)}',
                ),
              ],
            ),
            if (booking.discountAmount != null &&
                booking.discountAmount! > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Loyalty Points Discount'),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.card_giftcard,
                        size: 14,
                        color: Colors.purple[700],
                      ),
                    ],
                  ),
                  Text(
                    '- PKR ${booking.discountAmount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.purple[700],
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
                  'PKR ${booking.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Status'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: booking.isPaid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: booking.isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    booking.isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: booking.isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.isPaid) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method'),
                  Text(
                    booking.paymentMethod.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (booking.loyaltyPointsEarned != null &&
                booking.loyaltyPointsEarned! > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loyalty Points Earned'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${booking.loyaltyPointsEarned}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final booking = _booking!;
    final canCancel = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.rescheduled,
    ].contains(booking.statusEnum);

    final canReschedule = [
      BookingStatus.pending,
      BookingStatus.confirmed,
    ].contains(booking.statusEnum);

    final canApplyPoints = [
          BookingStatus.pending,
          BookingStatus.confirmed,
          BookingStatus.rescheduled,
        ].contains(booking.statusEnum) &&
        (booking.loyaltyPointsRedeemed == null ||
            booking.loyaltyPointsRedeemed == 0);

    final canReview = booking.statusEnum == BookingStatus.completed &&
        _auth.currentUser?.uid == booking.userId;

    if (!canCancel && !canReschedule && !canApplyPoints && !canReview) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCancel)
          ElevatedButton.icon(
            onPressed: _showCancelDialog,
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text('Cancel Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (canCancel && (canReschedule || canApplyPoints))
          const SizedBox(height: 12),
        if (canReschedule)
          ElevatedButton.icon(
            onPressed: _showRescheduleDialog,
            icon: const Icon(Icons.event_repeat, color: Colors.white),
            label: const Text('Reschedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (canReschedule && canApplyPoints) const SizedBox(height: 12),
        if (canApplyPoints)
          ElevatedButton.icon(
            onPressed: _showRedeemPointsDialog,
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            label: const Text('Apply Loyalty Points'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (canReview)
          Column(
            children: [
              if (canCancel || canReschedule || canApplyPoints)
                const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _reviewService.isBookingReviewed(booking.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final isReviewed = snapshot.data ?? false;
                  return ElevatedButton.icon(
                    onPressed: () =>
                        _navigateToReviewScreen(booking, isReviewed),
                    icon: Icon(isReviewed ? Icons.rate_review : Icons.star,
                        color: Colors.white),
                    label: Text(
                      isReviewed ? 'View Your Review' : 'Rate & Review Worker',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  void _navigateToReviewScreen(Booking booking, bool isReviewed) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          booking: booking,
          isReviewed: isReviewed,
        ),
      ),
    );

    if (result == true) {
      // Refresh the booking details after review is submitted
      _loadBooking();
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.purple, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
