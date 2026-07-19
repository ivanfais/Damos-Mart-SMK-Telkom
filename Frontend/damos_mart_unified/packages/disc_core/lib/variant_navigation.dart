import 'package:flutter/scheduler.dart';

import 'unified_host_bridge.dart';

typedef VariantRouteGo = void Function(String location);

/// Returns variant apps to splash when the unified host switches DISC themes.
void scheduleUnifiedSplashReset(VariantRouteGo goToSplash) {
  void goSplash() => goToSplash('/');

  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!UnifiedHostBridge.takeSplashReset()) return;
    goSplash();
    SchedulerBinding.instance.addPostFrameCallback((_) => goSplash());
  });
}
