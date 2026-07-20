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

  static const int _maxSearchHistory = 10;

  List<String> getSearchHistory() {
    return _prefs.getStringList(AppConstants.keySearchHistory) ?? [];
  }

  Future<void> addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final history = getSearchHistory()
      ..removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    history.insert(0, trimmed);

    if (history.length > _maxSearchHistory) {
      history.removeRange(_maxSearchHistory, history.length);
    }

    await _prefs.setStringList(AppConstants.keySearchHistory, history);
  }

  Future<void> removeSearchHistory(String query) async {
    final history = getSearchHistory()
      ..removeWhere((item) => item == query);
    await _prefs.setStringList(AppConstants.keySearchHistory, history);
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(AppConstants.keySearchHistory);
  }
}
