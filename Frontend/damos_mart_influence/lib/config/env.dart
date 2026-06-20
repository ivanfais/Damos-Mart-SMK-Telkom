/// Runtime configuration via `--dart-define`.
///
/// Local dev (default):
///   flutter run -d chrome
///
/// Staging / user testing build:
///   flutter build web --release \
///     --dart-define=APP_ENV=staging \
///     --dart-define=API_BASE_URL=https://your-api.example.com
class Env {
  /// `development` | `staging` | `production`
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// API origin without trailing slash, e.g. `https://api.example.com` or `http://localhost:3000`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
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
