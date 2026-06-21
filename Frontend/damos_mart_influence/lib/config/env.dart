/// Runtime configuration via `--dart-define`.
///
/// Default: Railway production API.
///
/// Local backend:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=APP_ENV=development
class Env {
  static const String _railwayApiOrigin =
      'https://damos-mart-smk-telkom-production.up.railway.app';

  /// `development` | `staging` | `production`
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );

  /// API origin without trailing slash, e.g. `https://api.example.com` or `http://localhost:3000`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _railwayApiOrigin,
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';

  static String get baseUrl => '$_normalizedApiBase/api/v1';
  static String get webSocketUrl => _normalizedApiBase;

  static String get _normalizedApiBase {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 30000;
}
