import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service_provider/registration/worker_registration_steps.dart';
import '../../service_provider/registration/pending_approval_page.dart';
import 'package:khidmat/app_screens/drawer/about.dart';
import 'package:khidmat/app_screens/drawer/privacy_policy.dart';
import 'package:khidmat/app_screens/drawer/terms_and_conditions.dart';
import '../../services_for_users/user_packages_screen.dart';
import '../../services_for_users/loyalty_points_screen.dart';
import '../../services_for_users/referral_screen.dart';
import '../../chat/conversations_screen.dart';
import '../../services_for_users/active_negotiations_screen.dart';

import '../../admin_module/dashboard/admin_ui.dart';
import '../../email_auth/login_page.dart';
import '../home_page.dart';
import '../../worker/worker_dashboard.dart' as worker;
import '../../utils/user_mode.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show LocaleProvider;

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.purple.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.purple.shade700, size: 28),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.confirmLogout,
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            AppLocalizations.of(context)!.areYouSureLogout,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void showAdminPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const AdminPasswordDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.purple),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
                child:
                    Text(AppLocalizations.of(context)!.errorFetchingUserData)),
          );
        }
        final user = snapshot.data!;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                body: Center(
                    child:
                        Text(AppLocalizations.of(context)!.userDataNotFound)),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final displayName =
                userData['full_name'] ?? AppLocalizations.of(context)!.noName;
            final email = user.email ?? AppLocalizations.of(context)!.noEmail;

            return Scaffold(
              body: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(displayName),
                      accountEmail: Text(email),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.home, color: Colors.blue),
                      title: Text(AppLocalizations.of(context)!.home),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.handshake, color: Colors.orange),
                      title: Text('Negotiations'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ActiveNegotiationsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat, color: Colors.purple),
                      title:
                          Text(AppLocalizations.of(context)!.myConversations),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversationsScreen(),
                          ),
                        );
                      },
                    ),
                    // ListTile(
                    //   leading: const Icon(Icons.inventory, color: Colors.teal),
                    //   title: Text(AppLocalizations.of(context)!.myPackages),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const UserPackagesScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    ListTile(
                      leading:
                          const Icon(Icons.card_giftcard, color: Colors.amber),
                      title: Text(AppLocalizations.of(context)!.loyaltyPoints),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoyaltyPointsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share, color: Colors.green),
                      title: Text(AppLocalizations.of(context)!.referral),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReferralScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.indigo),
                      title: Text(AppLocalizations.of(context)!.aboutUs),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description,
                          color: Colors.deepOrange),
                      title: Text(
                          AppLocalizations.of(context)!.termsAndConditions),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TermsAndConditionsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.privacy_tip, color: Colors.brown),
                      title: Text(AppLocalizations.of(context)!.privacyPolicy),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _LanguageDropdownButton(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(AppLocalizations.of(context)!.logout),
                      onTap: () => logout(context),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await UserMode.setWorkerMode(true);
                          if (!context.mounted) return;

                          final user = FirebaseAuth.instance.currentUser;
                          // Check if worker is already registered
                          if (user != null) {
                            final workerDoc = await FirebaseFirestore.instance
                                .collection('workers')
                                .doc(user.uid)
                                .get();

                            if (!context.mounted) return;

                            if (!workerDoc.exists) {
                              // Not registered, show registration form
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WorkerRegistrationSteps(),
                                ),
                                (route) => false,
                              );
                              return;
                            }

                            final workerData =
                                workerDoc.data() as Map<String, dynamic>;
                            if (workerData['status'] == 'pending') {
                              // Show pending approval page
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PendingApprovalPage(),
                                ),
                                (route) => false,
                              );
                              return;
                            }
                          }

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const worker.WorkerDashboard(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Switch to Worker Mode',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminPasswordDialog extends StatefulWidget {
  const AdminPasswordDialog({super.key});

  @override
  State<AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<AdminPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscured = true;
  String? _errorMessage;

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  void _validateAndSubmit(BuildContext context) {
    String password = _passwordController.text.trim();
    if (password == "1234") {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminPage(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseEnterValidPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.enterAdminPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _isObscured,
            style: const TextStyle(color: Colors.black), // Text color
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              labelStyle:
                  const TextStyle(color: Colors.black), // Label text color
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility
                      : Icons.visibility_off, // Icon color
                ),
                onPressed: _togglePasswordVisibility,
              ),
              errorText: _errorMessage,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.black), // Underline color when focused
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.black), // Underline color when not focused
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            _validateAndSubmit(context);
          },
          child: Text(
            AppLocalizations.of(context)!.submit,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageDropdownButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;
    return DropdownButtonFormField<String>(
      value: currentLocale,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.language,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
      icon: const Icon(Icons.language, color: Colors.purple),
      items: [
        DropdownMenuItem(
          value: 'en',
          child: Row(
            children: [
              const Icon(Icons.language, color: Colors.blue),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.english),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'ur',
          child: Row(
            children: [
              const Icon(Icons.language, color: Colors.green),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.urdu),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          localeProvider.setLocale(Locale(value));
        }
      },
    );
  }
}
