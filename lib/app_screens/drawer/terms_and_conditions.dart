import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Welcome to KhidmatGaar!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'By downloading, installing, or using KhidmatGaar, you agree to abide by the following terms and conditions:',
            ),
            SizedBox(height: 10),
            Text(
              '1. Usage: KhidmatGaar provides a platform to connect users with service professionals. Users must use the app for lawful purposes only.',
            ),
            Text(
              '2. Service Quality: While KhidmatGaar strives to connect users with reliable professionals, we do not guarantee the quality of services provided by third-party service providers.',
            ),
            Text(
              '3. Payment: Users agree to pay for services rendered through the KhidmatGaar platform according to the agreed-upon rates.',
            ),
            Text(
              '4. User Conduct: Users must behave respectfully towards service providers and other users of the app. Any abusive behavior will result in account suspension.',
            ),
            Text(
              '5. Privacy: KhidmatGaar respects user privacy and handles personal data in accordance with our Privacy Policy.',
            ),
            SizedBox(height: 20),
            Text(
              'By using KhidmatGaar, you acknowledge that you have read, understood, and agreed to these terms and conditions.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Text(
              'For any queries or concerns regarding these terms and conditions, please contact us at support@khidmatgaar.com.',
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
