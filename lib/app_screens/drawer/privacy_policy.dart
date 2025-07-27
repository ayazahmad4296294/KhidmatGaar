import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'At KhidmatGaar, we prioritize the privacy and security of our users\' personal information. This Privacy Policy outlines how we collect, use, and protect your data:',
            ),
            SizedBox(height: 10),
            Text(
              '1. Information Collection: We collect personal information such as name, email address, phone number, and location to provide our services effectively.',
            ),
            Text(
              '2. Information Usage: We use the collected information to connect users with service providers, process payments, and improve our services.',
            ),
            Text(
              '3. Information Sharing: We may share your information with third-party service providers to fulfill service requests. We do not sell or rent your personal information to third parties.',
            ),
            Text(
              '4. Data Security: We implement security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
            ),
            Text(
              '5. Consent: By using KhidmatGaar, you consent to the collection and use of your personal information as outlined in this Privacy Policy.',
            ),
            SizedBox(height: 20),
            Text(
              'For any questions or concerns regarding your privacy, please contact us at privacy@khidmatgaar.com.',
            ),
            SizedBox(height: 20),
            Text(
              'This Privacy Policy is effective as of [Effective Date] and may be updated periodically. We encourage you to review this Privacy Policy regularly for any changes.',
            ),
            SizedBox(height: 20),
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
