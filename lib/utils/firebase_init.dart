import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// A utility class to safely initialize Firebase only once.
class FirebaseInit {
  static bool _initialized = false;

  /// Initialize Firebase if it hasn't been initialized yet.
  /// Returns true if initialization was performed, false if it was already initialized.
  static Future<bool> ensureInitialized() async {
    if (!_initialized && Firebase.apps.isEmpty) {
      try {
        if (kIsWeb) {
          // Special handling for web platform
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('Firebase initialized for web platform successfully');
        } else {
          // Mobile and desktop platforms
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('Firebase initialized for non-web platform successfully');
        }
        _initialized = true;
        return true;
      } catch (e) {
        debugPrint('Error initializing Firebase: $e');
        // Don't rethrow - we want the app to continue even if Firebase fails
        // This helps prevent white screens
        return false;
      }
    }
    return false;
  }

  /// Checks if Firebase is already initialized.
  static bool get isInitialized => _initialized || Firebase.apps.isNotEmpty;
}
