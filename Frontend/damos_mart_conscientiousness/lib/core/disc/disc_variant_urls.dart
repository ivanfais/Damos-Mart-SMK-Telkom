import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import 'disc_session_handoff_platform.dart';
import 'disc_variant.dart';

/// Same-origin path for each DISC app on one domain.
class DiscVariantUrls {
  static const Map<DiscVariant, String> paths = {
    DiscVariant.influence: '/influence/',
    DiscVariant.dominance: '/dominance/',
    DiscVariant.steadiness: '/steadiness/',
    DiscVariant.conscientiousness: '/conscientiousness/',
  };

  static String baseUrlFor(DiscVariant variant) {
    final origin = _webOrigin.replaceAll(RegExp(r'/$'), '');
    final path = paths[variant] ?? '/';
    return '$origin$path';
  }

  static String get _webOrigin {
    if (Env.appWebOrigin.isNotEmpty) {
      return Env.appWebOrigin.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return '';
  }

  /// Detects variant from current browser path (production path deploy).
  static DiscVariant? variantFromCurrentLocation() {
    if (!kIsWeb) return null;

    final path = Uri.base.path;
    for (final entry in paths.entries) {
      final segment = entry.value.replaceAll(RegExp(r'^/|/$'), '');
      if (path == entry.value ||
          path == '/$segment' ||
          path.startsWith(entry.value) ||
          path.startsWith('/$segment/')) {
        return entry.key;
      }
    }
    return null;
  }

  static bool get isPathDeployed => variantFromCurrentLocation() != null;

  static void navigateTo(String url) => navigateToUrl(url);
}
