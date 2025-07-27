// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/negotiation.dart';
import '../services/negotiation_service.dart';
import 'price_negotiation_screen.dart';

class ActiveNegotiationsScreen extends StatefulWidget {
  const ActiveNegotiationsScreen({super.key});

  @override
  State<ActiveNegotiationsScreen> createState() =>
      _ActiveNegotiationsScreenState();
}

class _ActiveNegotiationsScreenState extends State<ActiveNegotiationsScreen> {
  final NegotiationService _negotiationService = NegotiationService();
  bool _isLoading = true;
  List<PriceNegotiation> _activeNegotiations = [];

  @override
  void initState() {
    super.initState();
    _loadNegotiations();
  }

  Future<void> _loadNegotiations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _activeNegotiations = await _negotiationService.getCustomerNegotiations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading negotiations: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueNegotiation(PriceNegotiation negotiation) async {
    // Get worker name from Firestore
    String workerName = 'Service Provider';
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(negotiation.workerId)
          .get();

      if (workerDoc.exists) {
        workerName = workerDoc.data()?['name'] ?? 'Service Provider';
      }
    } catch (e) {
      print('Error getting worker name: $e');
    }

    if (!mounted) return;

    // Navigate to negotiation screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceNegotiationScreen(
          workerId: negotiation.workerId,
          workerName: workerName,
          serviceName: negotiation.serviceName,
          bookingId: negotiation.bookingId,
          initialPrice: negotiation.initialPrice,
        ),
      ),
    );

    // Refresh list after returning
    _loadNegotiations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Negotiations'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : RefreshIndicator(
              onRefresh: _loadNegotiations,
              child: _activeNegotiations.isEmpty
                  ? _buildEmptyState()
                  : _buildNegotiationsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Negotiations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any active price negotiations. Start negotiating prices with service providers to get the best deal!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeNegotiations.length,
      itemBuilder: (context, index) {
        final negotiation = _activeNegotiations[index];
        return _buildNegotiationCard(negotiation);
      },
    );
  }

  Widget _buildNegotiationCard(PriceNegotiation negotiation) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(negotiation.updatedAt);
    final formattedTime = timeFormat.format(negotiation.updatedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  child: Icon(
                    _getServiceIcon(negotiation.serviceName),
                    color: Colors.purple,
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
                        ),
                      ),
                      Text(
                        'Last updated: $formattedDate at $formattedTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Initial Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'PKR${negotiation.initialPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current Offer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'PKR${negotiation.currentOffer.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(
                    'By: ${negotiation.offerBy == 'worker' ? 'Provider' : 'You'}',
                    style: TextStyle(
                      color: negotiation.offerBy == 'worker'
                          ? Colors.blue[800]
                          : Colors.green[800],
                    ),
                  ),
                  backgroundColor: negotiation.offerBy == 'worker'
                      ? Colors.blue[100]
                      : Colors.green[100],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    negotiation.offerBy == 'worker' ? 'Your Turn' : 'Waiting',
                    style: TextStyle(
                      color: negotiation.offerBy == 'worker'
                          ? Colors.orange[800]
                          : Colors.grey[800],
                    ),
                  ),
                  backgroundColor: negotiation.offerBy == 'worker'
                      ? Colors.orange[100]
                      : Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _continueNegotiation(negotiation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  negotiation.offerBy == 'worker'
                      ? 'Respond to Offer'
                      : 'View Negotiation',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'maid':
        return Icons.cleaning_services;
      case 'cook':
        return Icons.restaurant;
      case 'driver':
        return Icons.drive_eta;
      case 'security guard':
        return Icons.security;
      case 'baby care taker':
        return Icons.child_care;
      case 'gardener':
        return Icons.grass;
      case 'handyman':
        return Icons.handyman;
      case 'locksmith':
        return Icons.lock;
      case 'auto mechanic':
        return Icons.car_repair;
      case 'chef':
        return Icons.fastfood;
      default:
        return Icons.home_repair_service;
    }
  }
}
