import 'package:flutter/material.dart';
import 'add_prebuilt_packages.dart';
import 'firebase_init.dart';

// Run this file to populate the prebuilt_packages collection in Firestore
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use our centralized Firebase initialization
  await FirebaseInit.ensureInitialized();

  await AddPreBuiltPackages.addPackages();
  print('Setup complete!');
}
