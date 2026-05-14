import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const _firstLaunchKey = 'isFirstLaunch';
  static const _manualLogoutKey = 'manualLogout';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  static Future<void> setLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  static Future<void> setManualLogout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualLogoutKey, value);
  }

  static Future<bool> wasManualLogout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_manualLogoutKey) ?? false;
  }

  // ⭐⭐ أضيفي هذه هنا
  static Future<void> clearManualLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_manualLogoutKey);
  }
}
