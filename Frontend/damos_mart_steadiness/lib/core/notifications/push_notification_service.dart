import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../storage/prefs_storage.dart';
import 'notification_payload.dart';

typedef NotificationTapCallback = void Function(String? payload);

/// Native push notifications (Android/iOS status bar) triggered by realtime socket events.
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();

  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _queueChannelId = 'damos_queue_channel';
  static const String _queueChannelName = 'Status Pesanan';
  static const String _queueChannelDescription =
      'Notifikasi status antrean dan pesanan siap diambil';

  static const String _complaintChannelId = 'damos_complaint_channel';
  static const String _complaintChannelName = 'Status Komplain';
  static const String _complaintChannelDescription =
      'Notifikasi pembaruan status dan balasan komplain';

  bool _initialized = false;
  bool _permissionRequested = false;
  NotificationTapCallback? _tapHandler;
  String? _pendingColdStartPayload;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void registerTapHandler(NotificationTapCallback handler) {
    _tapHandler = handler;
    final pending = _pendingColdStartPayload;
    if (pending != null) {
      _pendingColdStartPayload = null;
      handler(pending);
    }
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
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _queueChannelId,
          _queueChannelName,
          description: _queueChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _complaintChannelId,
          _complaintChannelName,
          description: _complaintChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _pendingColdStartPayload = launchDetails!.notificationResponse?.payload;
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

  String? _queuePayload({String? orderId, String? queueId}) {
    if (orderId != null && orderId.isNotEmpty) {
      return NotificationPayload.orderDetail(orderId);
    }
    if (queueId != null && queueId.isNotEmpty) {
      return NotificationPayload.queueDetail(queueId);
    }
    return null;
  }

  Future<void> showQueueReady({
    required String queueNumber,
    String? orderId,
    String? queueId,
    String? orderNumber,
  }) {
    final label = orderNumber ?? queueNumber;
    return show(
      id: _idFor('queue_ready', orderId ?? queueId ?? queueNumber),
      title: 'Pesanan Siap Diambil!',
      body:
          'Pesanan $label siap diambil. Buka detail pesanan dan tunjukkan QR Pengambilan di kasir.',
      payload: _queuePayload(orderId: orderId, queueId: queueId),
      channelId: _queueChannelId,
      channelName: _queueChannelName,
      channelDescription: _queueChannelDescription,
    );
  }

  Future<void> showQueueCalled({
    required String queueNumber,
    String? orderId,
    String? queueId,
    String? orderNumber,
  }) {
    final label = orderNumber ?? queueNumber;
    return show(
      id: _idFor('queue_called', orderId ?? queueId ?? queueNumber),
      title: 'Antrean Dipanggil',
      body: 'Pesanan $label sedang disiapkan oleh petugas koperasi.',
      payload: _queuePayload(orderId: orderId, queueId: queueId),
      channelId: _queueChannelId,
      channelName: _queueChannelName,
      channelDescription: _queueChannelDescription,
    );
  }

  Future<void> showOrderStatusUpdate({
    required String orderId,
    required String title,
    required String body,
  }) {
    return show(
      id: _idFor('order_status', orderId),
      title: title,
      body: body,
      payload: NotificationPayload.orderDetail(orderId),
      channelId: _queueChannelId,
      channelName: _queueChannelName,
      channelDescription: _queueChannelDescription,
    );
  }

  Future<void> showOrderCompleted({
    required String orderId,
    String? orderNumber,
  }) {
    final label = orderNumber ?? 'pesanan Anda';
    return show(
      id: _idFor('order_completed', orderId),
      title: 'Pesanan Selesai',
      body: 'Pesanan $label telah selesai diambil. Terima kasih telah berbelanja!',
      payload: NotificationPayload.orderDetail(orderId),
      channelId: _queueChannelId,
      channelName: _queueChannelName,
      channelDescription: _queueChannelDescription,
    );
  }

  Future<void> showComplaintUpdate({
    required String complaintId,
    required String title,
    required String body,
  }) {
    return show(
      id: _idFor('complaint', complaintId),
      title: title,
      body: body,
      payload: NotificationPayload.complaintDetail(complaintId),
      channelId: _complaintChannelId,
      channelName: _complaintChannelName,
      channelDescription: _complaintChannelDescription,
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!isSupported || !_initialized) return;
    if (!PrefsStorage.instance.getNotificationsEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
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
