import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  // Singleton instance
  static final SecureStorage instance = SecureStorage._internal();

  SecureStorage._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAccessToken, token);
      return;
    }
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.keyAccessToken);
    }
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyRefreshToken, token);
      return;
    }
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.keyRefreshToken);
    }
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    final jsonStr = jsonEncode(userMap);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserData, jsonStr);
      return;
    }
    await _storage.write(key: AppConstants.keyUserData, value: jsonStr);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? jsonStr;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      jsonStr = prefs.getString(AppConstants.keyUserData);
    } else {
      jsonStr = await _storage.read(key: AppConstants.keyUserData);
    }
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAccessToken);
      await prefs.remove(AppConstants.keyRefreshToken);
      await prefs.remove(AppConstants.keyUserData);
      return;
    }
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserData);
  }
}
