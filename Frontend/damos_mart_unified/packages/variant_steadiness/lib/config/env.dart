/// Runtime configuration via `--dart-define`.
///
/// Default: Railway production API (sama dengan admin production).
///
/// Backend lokal (Laragon):
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
class Env {
  static const String _railwayApiOrigin =
      'https://damos-mart-smk-telkom-production.up.railway.app';

  /// `development` | `staging` | `production`
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );

  /// Default Railway — selaras dengan admin production.
  /// Lokal: `--dart-define=API_BASE_URL=http://localhost:3000`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _railwayApiOrigin,
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';

  static String get baseUrl {
    final normalized = _normalizedApiBase;
    if (normalized.endsWith('/api/v1')) {
      return normalized;
    }
    return '$normalized/api/v1';
  }

  static String get webSocketUrl => _normalizedApiBase;

  static String get _normalizedApiBase {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 45000;

  /// Origin web tunggal, mis. `https://damosmart.app` (tanpa trailing slash).
  static const String appWebOrigin = String.fromEnvironment(
    'APP_WEB_ORIGIN',
    defaultValue: '',
  );
}
