import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({Key? key, required this.bookingId})
      : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showErrorSnackBar('Error loading booking details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
              : _buildBookingDetails(),
    );
  }

  Widget _buildBookingDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${_booking!.id?.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDetailItem('Service', _booking!.serviceType),
                  _buildDetailItem('Status', _booking!.status),
                  _buildDetailItem(
                    'Worker',
                    _booking!.workerName,
                  ),
                  _buildDetailItem(
                    'Date & Time',
                    _formatDateTime(_booking!.scheduledDateTime),
                  ),
                  _buildDetailItem('Address', _booking!.address),
                  _buildDetailItem(
                    'Price',
                    'PKR ${_booking!.price.toStringAsFixed(2)}',
                  ),
                  if (_booking!.notes != null && _booking!.notes!.isNotEmpty)
                    _buildDetailItem('Notes', _booking!.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_canCancel())
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cancelBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _canCancel() {
    if (_booking == null) return false;

    // Can cancel if status is pending or confirmed
    return _booking!.status == BookingStatus.pending.value ||
        _booking!.status == BookingStatus.confirmed.value;
  }

  Future<void> _cancelBooking() async {
    try {
      await _bookingService.cancelBooking(_booking?.id ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the booking details
      _loadBookingDetails();
    } catch (e) {
      _showErrorSnackBar('Error cancelling booking: $e');
    }
  }
}
