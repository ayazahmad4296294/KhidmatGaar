import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About KhidmatGaar'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'KhidmatGaar - Har Waqt Hazir',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                "KhidmatGaar is dedicated to bringing you the best electrician and home services right to your doorstep. Our platform connects you with trusted professionals, ensuring prompt and efficient solutions for your needs. With KhidmatGaar, you can rest assured that your home services are in safe hands.",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16),
              ),
              // SizedBox(height: 20),
              // Text(
              //   'Version: 1.0.0',
              //   style: TextStyle(fontStyle: FontStyle.italic),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
