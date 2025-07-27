import 'package:shared_preferences/shared_preferences.dart';

class UserMode {
  static const String _key = 'user_mode';

  static Future<void> setWorkerMode(bool isWorker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isWorker);
  }

  static Future<bool> isWorkerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}
