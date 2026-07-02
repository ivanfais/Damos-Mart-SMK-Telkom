import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../storage/prefs_storage.dart';
import 'notification_payload.dart';

typedef NotificationTapCallback = void Function(String? payload);

/// Shows native push notifications in the device status bar (Android/iOS).
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();

  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'damos_queue_channel';
  static const String _channelName = 'Status Pesanan';
  static const String _channelDescription =
      'Notifikasi status antrean dan pesanan siap diambil';

  bool _initialized = false;
  bool _permissionRequested = false;
  NotificationTapCallback? _tapHandler;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void registerTapHandler(NotificationTapCallback handler) {
    _tapHandler = handler;
  }

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _tapHandler?.call(response.payload);
  }

  Future<void> ensurePermission() async {
    if (!isSupported || _permissionRequested) return;
    _permissionRequested = true;

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showQueueReady({
    required String queueNumber,
    String? orderId,
    String? orderNumber,
  }) {
    final label = orderNumber ?? queueNumber;
    return show(
      id: _idFor('queue_ready', orderId ?? queueNumber),
      title: 'Pesanan Siap Diambil!',
      body:
          'Pesanan $label siap diambil. Buka detail pesanan dan tunjukkan QR Pengambilan di kasir.',
      payload: orderId != null ? NotificationPayload.orderDetail(orderId) : null,
    );
  }

  Future<void> showQueueCalled({
    required String queueNumber,
    String? orderId,
    String? orderNumber,
  }) {
    final label = orderNumber ?? queueNumber;
    return show(
      id: _idFor('queue_called', orderId ?? queueNumber),
      title: 'Antrean Dipanggil',
      body: 'Pesanan $label sedang disiapkan oleh petugas koperasi.',
      payload: orderId != null ? NotificationPayload.orderDetail(orderId) : null,
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported || !_initialized) return;
    if (!PrefsStorage.instance.getNotificationsEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  int _idFor(String type, String key) {
    return '$type:$key'.hashCode.abs() % 100000;
  }
}
