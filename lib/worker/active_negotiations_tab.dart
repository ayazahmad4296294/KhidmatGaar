import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/negotiation.dart';
import '../services/negotiation_service.dart';
import '../service_provider/price_negotiation_worker_screen.dart';
import '../l10n/app_localizations.dart';

class ActiveNegotiationsTab extends StatefulWidget {
  const ActiveNegotiationsTab({Key? key}) : super(key: key);

  @override
  State<ActiveNegotiationsTab> createState() => _ActiveNegotiationsTabState();
}

class _ActiveNegotiationsTabState extends State<ActiveNegotiationsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NegotiationService _negotiationService = NegotiationService();
  bool _isLoading = true;
  List<PriceNegotiation> _negotiations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNegotiations();
  }

  Future<void> _loadNegotiations() async {
    if (_auth.currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view negotiations.';
      });
      return;
    }

    try {
      final negotiations = await _negotiationService.getWorkerNegotiations();
      setState(() {
        _negotiations = negotiations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading negotiations: $e';
      });
    }
  }

  Future<String> _getCustomerName(String customerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        }
      }
      return 'Customer';
    } catch (e) {
      return 'Customer';
    }
  }

  void _navigateToNegotiationDetail(PriceNegotiation negotiation) async {
    final customerName = await _getCustomerName(negotiation.customerId);
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceNegotiationWorkerScreen(
          negotiationId: negotiation.id,
          customerName: customerName,
        ),
      ),
    );

    if (result != null && result['accepted'] == true) {
      _showSnackBar('Negotiation accepted successfully!');
    }

    // Refresh the list
    _loadNegotiations();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.purple));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_negotiations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No active negotiations',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'When you negotiate with customers, it will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNegotiations,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _negotiations.length,
        itemBuilder: (context, index) {
          final negotiation = _negotiations[index];
          final isCustomerOffer = negotiation.offerBy == 'customer';

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _navigateToNegotiationDetail(negotiation),
              borderRadius: BorderRadius.circular(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getServiceIcon(negotiation.serviceName),
                            color: _getServiceColor(negotiation.serviceName),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                negotiation.serviceName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(negotiation.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEGOTIATING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer info
                        FutureBuilder<String>(
                          future: _getCustomerName(negotiation.customerId),
                          builder: (context, snapshot) {
                            final customerName = snapshot.data ?? 'Customer';
                            return Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  radius: 16,
                                  child: Icon(Icons.person,
                                      size: 20, color: Colors.grey.shade700),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Negotiating with: $customerName',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Negotiation details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.price_change, 'Initial Price',
                                  'PKR ${negotiation.initialPrice.toStringAsFixed(2)}'),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.arrow_downward,
                                'Current Offer',
                                'PKR ${negotiation.currentOffer.toStringAsFixed(2)}',
                                isBold: true,
                                valueColor: isCustomerOffer
                                    ? Colors.green
                                    : Colors.purple,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                isCustomerOffer
                                    ? Icons.account_circle
                                    : Icons.work,
                                'Last Offer By',
                                isCustomerOffer ? 'Customer' : 'You (Worker)',
                              ),
                              // Check offer history for message
                              if (negotiation.offerHistory.isNotEmpty &&
                                  negotiation.offerHistory.last.message !=
                                      null &&
                                  negotiation.offerHistory.last.message!
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.message,
                                  'Message',
                                  negotiation.offerHistory.last.message!,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // View details button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _navigateToNegotiationDetail(negotiation),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('View Details & Respond'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'maid':
        return Icons.cleaning_services;
      case 'cook':
        return Icons.restaurant;
      case 'driver':
        return Icons.drive_eta;
      case 'security guard':
        return Icons.security;
      case 'gardener':
        return Icons.grass;
      case 'baby care taker':
        return Icons.child_care;
      case 'handyman':
        return Icons.handyman;
      case 'locksmith':
        return Icons.lock;
      case 'auto mechanic':
        return Icons.car_repair;
      case 'chef':
        return Icons.restaurant;
      default:
        return Icons.work;
    }
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'maid':
        return Colors.teal;
      case 'cook':
        return Colors.orange;
      case 'driver':
        return Colors.blue;
      case 'security guard':
        return Colors.red;
      case 'gardener':
        return Colors.green;
      case 'baby care taker':
        return Colors.purple;
      case 'handyman':
        return Colors.orange;
      case 'locksmith':
        return Colors.grey;
      case 'auto mechanic':
        return Colors.blue;
      case 'chef':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
