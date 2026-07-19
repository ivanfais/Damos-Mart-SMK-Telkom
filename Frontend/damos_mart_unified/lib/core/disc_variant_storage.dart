import 'package:disc_core/disc_variant.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which DISC variant the user selected.
class DiscVariantStorage {
  static const _key = 'unified_selected_disc_variant';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static DiscVariant? read() {
    final raw = _prefs?.getString(_key);
    return DiscVariant.fromStored(raw);
  }

  static Future<void> save(DiscVariant variant) async {
    await _prefs?.setString(_key, variant.name);
  }

  static Future<void> clear() async {
    await _prefs?.remove(_key);
  }
}
