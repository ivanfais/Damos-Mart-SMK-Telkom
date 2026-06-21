import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/prefs_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences storage
  await PrefsStorage.instance.init();

  // Native push notifications (Android/iOS status bar)
  await PushNotificationService.instance.init();

  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const DamosMartApp());
}
