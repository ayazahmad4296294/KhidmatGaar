import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loyalty_points.dart';
import '../services/loyalty_service.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen>
    with SingleTickerProviderStateMixin {
  final LoyaltyService _loyaltyService = LoyaltyService();
  bool _isLoading = true;
  LoyaltyPointsSummary? _summary;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPointsSummary();
    // Check for expired points when screen loads
    _checkExpiredPoints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPointsSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _loyaltyService.getUserPointsSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading points: $e')),
      );
    }
  }

  Future<void> _checkExpiredPoints() async {
    try {
      await _loyaltyService.checkForExpiredPoints();
      // Reload summary after checking for expired points
      _loadPointsSummary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking expired points: $e')),
      );
    }
  }

  void _showRedeemDialog() {
    final availablePoints = _summary?.availablePoints ?? 0;
    if (availablePoints < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least 500 points to redeem')),
      );
      return;
    }

    final TextEditingController pointsController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Points'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Points: $availablePoints'),
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

                  if (points > availablePoints) {
                    return 'You don\'t have enough points';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Redeem your points for discount on your next service booking.',
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
                  final success = await _loyaltyService.redeemPoints(
                    points: pointsToRedeem,
                    description: 'Points redeemed for discount',
                    referenceId:
                        DateTime.now().millisecondsSinceEpoch.toString(),
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Successfully redeemed $pointsToRedeem points!')),
                    );
                    _loadPointsSummary();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to redeem points')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error redeeming points: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text(
              'Redeem',
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
        title: const Text('Loyalty Points'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Points Summary'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRedeemDialog,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.redeem, color: Colors.white),
        label:
            const Text('Redeem Points', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final summary = _summary;
    if (summary == null) {
      return const Center(child: Text('No points summary available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points overview card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Available Points',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${summary.availablePoints}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPointsInfoColumn('Earned', summary.totalEarned),
                      _buildPointsInfoColumn('Redeemed', summary.totalRedeemed),
                      _buildPointsInfoColumn('Expired', summary.totalExpired),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // How to earn more points
          const Text(
            'How to Earn More Points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarningMethodCard(
            icon: Icons.check_circle,
            title: 'Complete a Booking',
            points: LoyaltyService.POINTS_PER_BOOKING,
            description: 'Earn points when you complete a service booking',
          ),
          _buildEarningMethodCard(
            icon: Icons.inventory,
            title: 'Purchase a Package',
            points: LoyaltyService.POINTS_PER_PACKAGE,
            description: 'Earn points when you purchase a service package',
          ),
          _buildEarningMethodCard(
            icon: Icons.people,
            title: 'Refer a Friend',
            points: LoyaltyService.POINTS_PER_REFERRAL,
            description:
                'Earn bonus points when a friend signs up using your referral',
          ),
          _buildEarningMethodCard(
            icon: Icons.star,
            title: 'High-Value Bookings',
            points: LoyaltyService.POINTS_THRESHOLD_BONUS,
            description:
                'Earn additional bonus points for bookings over PKR 5,000',
          ),

          const SizedBox(height: 24),

          // Redemption info
          const Text(
            'Redemption Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to Redeem',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Minimum 500 points required for redemption\n'
                    '• 500 points = PKR 100 discount\n'
                    '• Points can be redeemed for discounts on bookings\n'
                    '• Points expire one year from the date they were earned',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInfoColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningMethodCard({
    required IconData icon,
    required String title,
    required int points,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.purple,
          size: 32,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+$points pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<PointTransaction>>(
      stream: _loyaltyService.getUserPointTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Text('No transaction history yet'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(PointTransaction transaction) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(transaction.date);

    // Set icon and color based on transaction type
    IconData icon;
    Color color;
    String typeText;

    switch (transaction.type) {
      case 'earned':
        icon = Icons.add_circle;
        color = Colors.green;
        typeText = 'Earned';
        break;
      case 'redeemed':
        icon = Icons.redeem;
        color = Colors.purple;
        typeText = 'Redeemed';
        break;
      case 'expired':
        icon = Icons.access_time_filled;
        color = Colors.red;
        typeText = 'Expired';
        break;
      case 'bonus':
        icon = Icons.star;
        color = Colors.amber;
        typeText = 'Bonus';
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
        typeText = 'Unknown';
    }

    String pointsText = transaction.points.toString();
    if (transaction.type == 'earned' || transaction.type == 'bonus') {
      pointsText = '+$pointsText';
    } else if (transaction.type == 'redeemed' ||
        transaction.type == 'expired') {
      pointsText = '-$pointsText';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(transaction.description),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate),
          if (transaction.expiryDate != null)
            Text(
              'Expires: ${dateFormat.format(transaction.expiryDate!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pointsText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typeText,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
