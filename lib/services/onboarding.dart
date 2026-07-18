import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-time onboarding walkthrough has been seen, so it
/// shows only once per device/browser.
class Onboarding {
  Onboarding._();
  static const _key = 'onboarding_seen_v1';

  static Future<bool> seen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      // If storage is unavailable, don't block startup — treat as seen.
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {/* ignore */}
  }
}
