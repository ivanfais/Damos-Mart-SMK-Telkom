import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';
import '../disc/disc_variant.dart';

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

  Future<void> setSelectedDiscVariant(DiscVariant variant) async {
    await _prefs.setString(AppConstants.keySelectedDiscVariant, variant.name);
  }

  DiscVariant? getSelectedDiscVariant() {
    return DiscVariant.fromStored(_prefs.getString(AppConstants.keySelectedDiscVariant));
  }

  Future<void> clearSelectedDiscVariant() async {
    await _prefs.remove(AppConstants.keySelectedDiscVariant);
  }

  String _nicknameKey(String userId) => '${AppConstants.keyUserNicknamePrefix}$userId';

  Future<void> setUserNickname(String userId, String nickname) async {
    await _prefs.setString(_nicknameKey(userId), nickname.trim());
  }

  String? getUserNickname(String userId) {
    final value = _prefs.getString(_nicknameKey(userId));
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> clearUserNickname(String userId) async {
    await _prefs.remove(_nicknameKey(userId));
  }
}
