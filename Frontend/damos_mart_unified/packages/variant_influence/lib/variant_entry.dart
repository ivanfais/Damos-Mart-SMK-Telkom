import 'dart:async';

import 'package:disc_core/disc_variant.dart' as core;
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/disc/disc_variant.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/prefs_storage.dart';
import 'core/utils/damos_system_ui.dart';

class VariantEntry {
  static Future<void> bootstrap(core.DiscVariant activeVariant) async {
    DamosSystemUi.apply(DamosSystemUi.lightHeader);
    await PrefsStorage.instance.init();
    final local = DiscVariant.fromStored(activeVariant.name);
    if (local != null) {
      await PrefsStorage.instance.setSelectedDiscVariant(local);
    }
    unawaited(PushNotificationService.instance.init());
  }

  static Widget app() => const DamosMartApp();
}
