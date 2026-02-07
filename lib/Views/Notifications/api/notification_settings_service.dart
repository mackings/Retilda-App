import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _keyOrderUpdates = 'notify_order_updates';
  static const String _keyPromos = 'notify_promos';
  static const String _keyEmail = 'notify_email';

  Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'orderUpdates': prefs.getBool(_keyOrderUpdates) ?? true,
      'promos': prefs.getBool(_keyPromos) ?? false,
      'email': prefs.getBool(_keyEmail) ?? true,
    };
  }

  Future<void> saveSettings({
    required bool orderUpdates,
    required bool promos,
    required bool email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOrderUpdates, orderUpdates);
    await prefs.setBool(_keyPromos, promos);
    await prefs.setBool(_keyEmail, email);
  }
}
