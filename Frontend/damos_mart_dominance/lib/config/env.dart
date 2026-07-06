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

  /// Aktifkan simulasi pembayaran di APK release untuk uji internal.
  /// Production: `--dart-define=APP_ENV=production` (simulasi mati).
  /// Testing: default `staging` atau `--dart-define=ENABLE_PAYMENT_SIMULATION=true`.
  static const bool forcePaymentSimulation = bool.fromEnvironment(
    'ENABLE_PAYMENT_SIMULATION',
    defaultValue: false,
  );

  static bool get showPaymentSimulation =>
      forcePaymentSimulation || isDevelopment || isStaging;

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

  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 30000;

  /// Origin web tunggal, mis. `https://damosmart.app` (tanpa trailing slash).
  static const String appWebOrigin = String.fromEnvironment(
    'APP_WEB_ORIGIN',
    defaultValue: '',
  );
}
