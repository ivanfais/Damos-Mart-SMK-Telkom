import 'dart:convert';

import '../storage/prefs_storage.dart';
import '../storage/secure_storage.dart';
import 'disc_session_handoff_platform.dart';
import 'disc_variant.dart';

/// Passes auth session between DISC apps on different subdomains.
class DiscSessionHandoff {
  static const handoffQueryKey = 'disc_handoff';

  static Future<bool> tryImportFromUrl() async {
    final encoded = readHandoffParam();
    if (encoded == null || encoded.isEmpty) return false;

    try {
      final decoded = utf8.decode(base64Url.decode(_padBase64Url(encoded)));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;

      final accessToken = payload['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) return false;

      await SecureStorage.instance.saveAccessToken(accessToken);

      final refreshToken = payload['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await SecureStorage.instance.saveRefreshToken(refreshToken);
      }

      final user = payload['user'];
      if (user is Map<String, dynamic>) {
        await SecureStorage.instance.saveUserData(user);
      }

      final variantName = payload['discVariant'] as String?;
      final variant = DiscVariant.fromStored(variantName);
      if (variant != null) {
        await PrefsStorage.instance.setSelectedDiscVariant(variant);
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      clearHandoffParam();
    }
  }

  static Future<String?> exportEncoded() async {
    final accessToken = await SecureStorage.instance.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return null;

    final refreshToken = await SecureStorage.instance.getRefreshToken();
    final user = await SecureStorage.instance.getUserData();
    final variant = PrefsStorage.instance.getSelectedDiscVariant();

    final payload = <String, dynamic>{
      'accessToken': accessToken,
      if (refreshToken != null && refreshToken.isNotEmpty)
        'refreshToken': refreshToken,
      if (user != null) 'user': user,
      if (variant != null) 'discVariant': variant.name,
    };

    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  static void launchExternalApp({
    required String baseUrl,
    String? encodedHandoff,
  }) {
    final target = Uri.parse(baseUrl);
    final uri = encodedHandoff == null || encodedHandoff.isEmpty
        ? target
        : target.replace(
            queryParameters: {
              ...target.queryParameters,
              handoffQueryKey: encodedHandoff,
            },
          );
    navigateToUrl(uri.toString());
  }

  static String _padBase64Url(String value) {
    return value.padRight(
      value.length + ((4 - value.length % 4) % 4),
      '=',
    );
  }
}
