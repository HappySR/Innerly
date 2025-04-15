import 'package:shared_preferences/shared_preferences.dart';

class UserRole {
  static bool isTherapist = false;

  static const _key = 'isTherapist';

  static Future<void> saveRole(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    isTherapist = value;
    await prefs.setBool(_key, value);
  }

  static Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    isTherapist = prefs.getBool(_key) ?? false;
    print("Loaded role isTherapist: $isTherapist"); // Log the value
  }

}
