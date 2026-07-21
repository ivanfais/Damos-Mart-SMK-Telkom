import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/disc/disc_app_config.dart';
import 'core/disc/disc_session_handoff.dart';
import 'core/disc/disc_variant_urls.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/prefs_storage.dart';
import 'core/utils/damos_system_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Agar link email /reset-password?token=... bisa dibuka langsung di browser.
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  DamosSystemUi.apply(DamosSystemUi.lightHeader);

  // Initialize shared preferences storage
  await PrefsStorage.instance.init();

  await DiscSessionHandoff.tryImportFromUrl();

  final fromPath = DiscVariantUrls.variantFromCurrentLocation();
  final initialVariant = fromPath ?? DiscAppConfig.hostVariant;
  await PrefsStorage.instance.setSelectedDiscVariant(initialVariant);

  // Native push notifications (Android/iOS status bar)
  await PushNotificationService.instance.init();

  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const DamosMartApp());
}
