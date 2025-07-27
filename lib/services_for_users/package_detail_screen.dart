import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_package.dart';
import '../services/package_service.dart';

class PackageDetailScreen extends StatefulWidget {
  final String packageId;

  const PackageDetailScreen({
    super.key,
    required this.packageId,
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final PackageService _packageService = PackageService();
  bool _isLoading = true;
  ServicePackage? _package;
  PreBuiltPackage? _preBuiltPackage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final package = await _packageService.getPackageById(widget.packageId);
      setState(() {
        _package = package;
        _isLoading = false;
      });

      if (package == null) {
        setState(() {
          _errorMessage = 'Package not found';
        });
        return;
      }

      // If this is a pre-built package, load the details
      if (package.packageType == 'pre-built' &&
          package.preBuiltPackageId != null) {
        try {
          final preBuiltPackage = await _packageService
              .getPreBuiltPackageById(package.preBuiltPackageId!);
          setState(() {
            _preBuiltPackage = preBuiltPackage;
          });
        } catch (e) {
          print('Error loading pre-built package details: $e');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading package: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _package == null
                  ? const Center(child: Text('Package not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPackageHeader(),
                          const SizedBox(height: 24),
                          if (_preBuiltPackage != null) _buildPreBuiltInfo(),
                          const SizedBox(height: 24),
                          _buildServicesSection(),
                          const SizedBox(height: 24),
                          _buildPricingSection(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPackageHeader() {
    final package = _package!;
    final dateFormat = DateFormat('MMM d, yyyy');
    final createdAtFormatted = dateFormat.format(package.createdAt);

    // Calculate expiry date
    final expiryDate =
        package.createdAt.add(Duration(days: 30 * package.durationMonths));
    final expiryDateFormatted = dateFormat.format(expiryDate);

    // Determine status color
    Color statusColor;
    switch (package.status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Package #${package.id?.substring(0, 8) ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    package.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', createdAtFormatted),
            _buildInfoRow('Expires', expiryDateFormatted),
            _buildInfoRow('Duration', '${package.durationMonths} month(s)'),
            _buildInfoRow('Services', '${package.items.length} service(s)'),
            _buildInfoRow(
                'Type',
                package.packageType == 'pre-built'
                    ? 'Pre-built package'
                    : 'Custom package'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreBuiltInfo() {
    if (_preBuiltPackage == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre-Built Package Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _preBuiltPackage!.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _preBuiltPackage!.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Discount Applied: ${_preBuiltPackage!.discount.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
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

  Widget _buildServicesSection() {
    final services = _package!.items;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceItem(service, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(ServicePackageItem service, int number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.serviceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Provider: ${service.workerName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: PKR ${service.price.toStringAsFixed(2)}/month',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final package = _package!;
    final discountAmount =
        package.totalBeforeDiscount - package.totalAfterDiscount;
    final discountPercent =
        (discountAmount / package.totalBeforeDiscount) * 100;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package Pricing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              'Monthly Services Total',
              package.totalBeforeDiscount / package.durationMonths,
            ),
            _buildPriceRow(
              'Duration Factor',
              '${package.durationMonths} month(s)',
              isMonetary: false,
            ),
            const Divider(height: 24),
            _buildPriceRow(
              'Subtotal Before Discount',
              package.totalBeforeDiscount,
              isBold: true,
            ),
            if (package.packageType == 'pre-built' && _preBuiltPackage != null)
              _buildPriceRow(
                'Pre-built Package Discount (${_preBuiltPackage!.discount}%)',
                -package.totalBeforeDiscount * _preBuiltPackage!.discount / 100,
                isDiscount: true,
              )
            else
              _buildPriceRow(
                'Duration Discount (${ServicePackage.getDiscountPercentage(package.durationMonths)}%)',
                -ServicePackage.getDiscountPercentage(package.durationMonths) *
                    package.totalBeforeDiscount /
                    100,
                isDiscount: true,
              ),
            const Divider(height: 24),
            _buildPriceRow(
              'Total Package Price',
              package.totalAfterDiscount,
              isBold: true,
              isTotal: true,
            ),
            const SizedBox(height: 8),
            Text(
              'You saved PKR ${discountAmount.toStringAsFixed(2)} (${discountPercent.toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    dynamic value, {
    bool isMonetary = true,
    bool isBold = false,
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    String valueText;

    if (isMonetary) {
      valueText =
          'PKR ${(value is double ? value.toStringAsFixed(2) : value.toString())}';
    } else {
      valueText = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color:
                  isDiscount ? Colors.green : (isTotal ? Colors.purple : null),
            ),
          ),
        ],
      ),
    );
  }
}
