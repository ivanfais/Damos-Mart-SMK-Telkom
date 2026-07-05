import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/disc/disc_session_handoff.dart';
import 'core/disc/disc_variant_urls.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/prefs_storage.dart';
import 'core/utils/damos_system_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DamosSystemUi.apply(DamosSystemUi.lightHeader);
  
  // Initialize shared preferences storage
  await PrefsStorage.instance.init();

  await DiscSessionHandoff.tryImportFromUrl();

  // Hanya set dari URL path deploy (/steadiness/, dll) atau session handoff.
  // Jangan auto-set hostVariant — agar layar pilih DISC tampil sebelum splash.
  final fromPath = DiscVariantUrls.variantFromCurrentLocation();
  if (fromPath != null) {
    await PrefsStorage.instance.setSelectedDiscVariant(fromPath);
  }

  // Native push notifications (Android/iOS status bar)
  await PushNotificationService.instance.init();
  await PushNotificationService.instance.ensurePermission();

  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const DamosMartApp());
}
