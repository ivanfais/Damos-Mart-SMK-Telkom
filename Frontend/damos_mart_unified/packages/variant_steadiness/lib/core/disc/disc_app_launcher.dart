import 'package:disc_core/disc_variant.dart' as core;
import 'package:disc_core/unified_host_bridge.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import '../storage/prefs_storage.dart';
import 'disc_app_config.dart';
import 'disc_session_handoff.dart';
import 'disc_variant.dart';
import 'disc_variant_urls.dart';

class DiscAppLauncher {
  /// Returns variant for the currently running build/URL.
  static DiscVariant get activeVariant =>
      DiscVariantUrls.variantFromCurrentLocation() ?? DiscAppConfig.hostVariant;

  /// Switches DISC variant. Returns `true` when a full-page redirect started.
  static Future<bool> switchToVariant(DiscVariant variant) async {
    await PrefsStorage.instance.setSelectedDiscVariant(variant);

    final unified = UnifiedHostBridge.switchVariant;
    if (unified != null) {
      final coreVariant = core.DiscVariant.values.firstWhere((v) => v.name == variant.name);
      return unified(coreVariant);
    }

    if (!kIsWeb) return false;
    if (activeVariant == variant) return false;

    final targetUrl = _targetUrlFor(variant);
    if (targetUrl == null) return false;

    final handoff = await DiscSessionHandoff.exportEncoded();
    DiscSessionHandoff.launchExternalApp(
      baseUrl: targetUrl,
      encodedHandoff: handoff,
    );
    return true;
  }

  static String? _targetUrlFor(DiscVariant variant) {
    if (DiscVariantUrls.isPathDeployed) {
      return DiscVariantUrls.baseUrlFor(variant);
    }

    if (Env.appWebOrigin.isNotEmpty) {
      final origin = Env.appWebOrigin.replaceAll(RegExp(r'/$'), '');
      final path = DiscVariantUrls.paths[variant] ?? '/';
      return '$origin$path';
    }

    return null;
  }

  /// Message when web switch cannot redirect (single `flutter run` build).
  static String get singleBuildSwitchHint =>
      'Untuk pindah tema dengan tampilan berbeda, jalankan '
      'Frontend/scripts/dev_single_domain.ps1 lalu buka http://localhost:8080';
}
