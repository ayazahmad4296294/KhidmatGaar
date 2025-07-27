// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_package.dart';
import '../services/package_service.dart';
import 'package_creation_screen.dart';
import 'package_detail_screen.dart';
import 'prebuilt_packages_screen.dart';

class UserPackagesScreen extends StatefulWidget {
  const UserPackagesScreen({super.key});

  @override
  State<UserPackagesScreen> createState() => _UserPackagesScreenState();
}

class _UserPackagesScreenState extends State<UserPackagesScreen> {
  final PackageService _packageService = PackageService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service Packages'),
      ),
      body: StreamBuilder<List<ServicePackage>>(
        stream: _packageService.getUserPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.purple));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final packages = snapshot.data ?? [];

          if (packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You don\'t have any service packages yet',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PackageCreationScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text(
                          'Create Custom Package',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PreBuiltPackagesScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                        ),
                        child: const Text(
                          'Browse Pre-Built Packages',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return _buildPackageCard(package);
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'prebuiltPackages',
            backgroundColor: Colors.purple.shade700,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreBuiltPackagesScreen(),
                ),
              );
            },
            mini: true,
            child: const Icon(Icons.card_giftcard, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'customPackage',
            backgroundColor: Colors.purple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PackageCreationScreen(),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(ServicePackage package) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final createdAtFormatted = dateFormat.format(package.createdAt);

    // Calculate expiry date
    final expiryDate =
        package.createdAt.add(Duration(days: 30 * package.durationMonths));
    final expiryDateFormatted = dateFormat.format(expiryDate);

    // Determine status color
    Color statusColor;
    IconData statusIcon;
    switch (package.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDetailScreen(
                packageId: package.id!,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Package #${package.id?.substring(0, 8) ?? ''}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (package.packageType == 'pre-built')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: const Text(
                                    'PRE-BUILT',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 13, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              'Created: $createdAtFormatted',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.event,
                                size: 13, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              'Expires: $expiryDateFormatted',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      package.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 15, color: Colors.purple[200]),
                  const SizedBox(width: 4),
                  Text(
                    '${package.items.length} Services',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...package.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• ${item.serviceName}',
                        style: const TextStyle(fontSize: 13)),
                  )),
              if (package.items.length > 3)
                Text(
                  '• and ${package.items.length - 3} more...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Package Total:',
                        style: TextStyle(
                          fontSize: 13.5,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PKR ${package.totalAfterDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            package.durationMonths > 1
                                ? '(${package.durationMonths} months)'
                                : '(1 month)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (package.totalBeforeDiscount >
                          package.totalAfterDiscount)
                        Text(
                          'Saved: PKR ${(package.totalBeforeDiscount - package.totalAfterDiscount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (package.status != 'cancelled' &&
                          package.status != 'completed')
                        TextButton.icon(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 18),
                          onPressed: () => _cancelPackage(package.id!),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          label: const Text('Cancel'),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility,
                            color: Colors.white, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PackageDetailScreen(
                                packageId: package.id!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        label: const Text(
                          'View Details',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelPackage(String packageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Package'),
          content: const Text(
              'Are you sure you want to cancel this package? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _packageService.cancelPackage(packageId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling package: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
