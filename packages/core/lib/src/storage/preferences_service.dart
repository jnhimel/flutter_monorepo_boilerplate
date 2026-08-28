import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences] for simple flags (theme mode,
/// onboarding-seen). Call [init] once during bootstrap before reading.
class PreferencesService {
  SharedPreferences? _prefs;

  static const themeModeKey = 'theme_mode';
  static const onboardingSeenKey = 'onboarding_seen';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    final prefs = _prefs;
    assert(prefs != null, 'PreferencesService.init() must be awaited first.');
    return prefs!;
  }

  String? getString(String key) => _instance.getString(key);

  Future<void> setString(String key, String value) =>
      _instance.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _instance.getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) => _instance.setBool(key, value);
}
