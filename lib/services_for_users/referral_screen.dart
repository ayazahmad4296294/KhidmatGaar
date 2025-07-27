import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/loyalty_service.dart';
import 'dart:math';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoyaltyService _loyaltyService = LoyaltyService();

  String _referralCode = '';
  bool _isLoading = true;
  bool _generatingCode = false;
  final TextEditingController _codeController = TextEditingController();
  bool _applyingCode = false;
  String _errorMessage = '';
  bool _codeApplied = false;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          if (userData.containsKey('referralCode') &&
              userData['referralCode'] != null) {
            setState(() {
              _referralCode = userData['referralCode'];
            });
          }
        }
      }
    } catch (e) {
      print('Error loading referral code: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateReferralCode() async {
    if (_generatingCode) return;

    setState(() {
      _generatingCode = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Generate a unique code combining user ID and random characters
        final String uniqueCode = _generateUniqueCode(user.uid);

        // Save the code to the user document
        await _firestore.collection('users').doc(user.uid).update({
          'referralCode': uniqueCode,
        });

        setState(() {
          _referralCode = uniqueCode;
        });
      }
    } catch (e) {
      print('Error generating referral code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate referral code: $e')),
      );
    } finally {
      setState(() {
        _generatingCode = false;
      });
    }
  }

  String _generateUniqueCode(String userId) {
    // Take first 4 characters from user ID
    final String userPrefix = userId.substring(0, min(4, userId.length));

    // Generate 6 random alphanumeric characters
    const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    String randomString = '';

    for (int i = 0; i < 6; i++) {
      randomString += characters[random.nextInt(characters.length)];
    }

    // Combine for a 10-character code
    return '${userPrefix.toUpperCase()}$randomString';
  }

  Future<void> _applyReferralCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a referral code';
      });
      return;
    }

    if (_applyingCode) return;

    setState(() {
      _applyingCode = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _applyingCode = false;
        });
        return;
      }

      // Check if the user has already applied a referral code
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData['referralApplied'] == true) {
        setState(() {
          _errorMessage = 'You have already applied a referral code';
          _applyingCode = false;
        });
        return;
      }

      // Check if the user is trying to use their own code
      if (userData != null && userData['referralCode'] == code) {
        setState(() {
          _errorMessage = 'You cannot use your own referral code';
          _applyingCode = false;
        });
        return;
      }

      // Find the referrer using the code
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid referral code';
          _applyingCode = false;
        });
        return;
      }

      final referrerId = querySnapshot.docs.first.id;

      // Update the current user
      await _firestore.collection('users').doc(user.uid).update({
        'referredBy': referrerId,
        'referralApplied': true,
        'referralAppliedDate': Timestamp.now(),
      });

      // Award points to both users
      await _loyaltyService.awardReferralPoints(referrerId);

      // Award points to the new user as well (300 points)
      await _loyaltyService.addPoints(
        points: 300,
        description: 'Welcome bonus for using a referral code',
        source: 'referral_bonus',
        referenceId: referrerId,
        isBonus: true,
      );

      setState(() {
        _codeApplied = true;
        _codeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Referral code applied successfully! You received 300 points.')),
      );
    } catch (e) {
      print('Error applying referral code: $e');
      setState(() {
        _errorMessage = 'Failed to apply code: $e';
      });
    } finally {
      setState(() {
        _applyingCode = false;
      });
    }
  }

  void _shareReferralCode() {
    if (_referralCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _referralCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Code copied to clipboard! You can now share it with friends.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Referral illustration
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/referral.png',
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.share,
                            size: 80,
                            color: Colors.purple,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info text
                  const Text(
                    'Refer friends and earn rewards!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your referral code with friends. When they sign up and enter your code, you both get 300 loyalty points!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Your referral code section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Your Referral Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_referralCode.isEmpty)
                            ElevatedButton(
                              onPressed: _generatingCode
                                  ? null
                                  : _generateReferralCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: _generatingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purple,
                                      ),
                                    )
                                  : const Text('Generate Code'),
                            )
                          else
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _referralCode,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: _referralCode));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Code copied to clipboard')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _shareReferralCode,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share Code'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Enter a referral code section
                  if (!_codeApplied)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Have a Referral Code?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                hintText: 'Enter referral code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorText: _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : null,
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  _applyingCode ? null : _applyReferralCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: _applyingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purple,
                                      ),
                                    )
                                  : const Text('Apply Code'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.green[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Referral Code Applied!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have successfully applied a referral code and received 300 loyalty points.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
