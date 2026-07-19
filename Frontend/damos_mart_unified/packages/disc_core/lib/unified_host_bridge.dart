import 'disc_variant.dart';

typedef UnifiedVariantSwitch = Future<bool> Function(DiscVariant variant);

/// Callback hook from unified host into variant DISC switchers.
class UnifiedHostBridge {
  static UnifiedVariantSwitch? switchVariant;
  static DiscVariant? hostActiveVariant;

  /// Skip host loading spinner when switching between variants.
  static bool fastVariantSwitch = false;

  /// Bumped on each profile/unified theme switch so variant GoRouters remount at splash.
  static int variantSessionId = 0;

  /// Force the mounted variant router back to splash (`/`) after a theme switch.
  static bool resetSplashOnMount = false;

  static bool takeSplashReset() {
    if (!resetSplashOnMount) return false;
    resetSplashOnMount = false;
    return true;
  }
}
