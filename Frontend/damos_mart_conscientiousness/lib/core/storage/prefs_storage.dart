import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';

class PrefsStorage {
  late final SharedPreferences _prefs;

  // Singleton instance
  static final PrefsStorage instance = PrefsStorage._internal();

  PrefsStorage._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keySettingsNotifications, enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool(AppConstants.keySettingsNotifications) ?? true;
  }

  Future<void> setDarkThemeEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keySettingsDarkTheme, enabled);
  }

  bool getDarkThemeEnabled() {
    return _prefs.getBool(AppConstants.keySettingsDarkTheme) ?? false;
  }
}
