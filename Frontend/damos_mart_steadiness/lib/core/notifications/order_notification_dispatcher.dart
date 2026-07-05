import 'package:flutter/foundation.dart';

import '../../data/models/notification_model.dart';
import 'push_notification_service.dart';

typedef OrderNotificationTapHandler = void Function({
  String? orderId,
  String? queueId,
  String? complaintId,
});

typedef NotificationBannerHandler = void Function({
  required String title,
  required String body,
  VoidCallback? onTap,
});

/// Menampilkan push/banner notifikasi pesanan dengan deduplikasi singkat.
class OrderNotificationDispatcher {
  OrderNotificationDispatcher._();

  static final OrderNotificationDispatcher instance = OrderNotificationDispatcher._();

  final Map<String, DateTime> _recentKeys = {};
  OrderNotificationTapHandler? _tapHandler;
  NotificationBannerHandler? _bannerHandler;

  void registerTapHandler(OrderNotificationTapHandler handler) {
    _tapHandler = handler;
  }

  void registerBannerHandler(NotificationBannerHandler handler) {
    _bannerHandler = handler;
  }

  bool _shouldShow(String key) {
    final now = DateTime.now();
    _recentKeys.removeWhere((_, at) => now.difference(at).inSeconds > 45);
    if (_recentKeys.containsKey(key)) return false;
    _recentKeys[key] = now;
    return true;
  }

  String _keyFor({
    String? id,
    required String title,
    String? referenceId,
    String? type,
  }) {
    return id ?? '$type:${referenceId ?? ''}:$title';
  }

  Future<void> showFromSocket(Map<String, dynamic> data) async {
    final title = data['title']?.toString() ?? 'Notifikasi';
    final body = data['body']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final referenceId = data['referenceId']?.toString();
    final id = data['id']?.toString();

    if (body.isEmpty) return;

    final key = _keyFor(id: id, title: title, referenceId: referenceId, type: type);
    if (!_shouldShow(key)) return;

    final targets = _resolveTargets(type: type, referenceId: referenceId, data: data);
    await _present(
      title: title,
      body: body,
      orderId: targets.orderId,
      queueId: targets.queueId,
      complaintId: targets.complaintId,
      queueNumber: data['queueNumber']?.toString(),
      orderNumber: data['orderNumber']?.toString(),
      paymentSuccess: title.toLowerCase().contains('pembayaran berhasil'),
      isQueueReady: type == 'QUEUE_READY',
      isCompleted: body.toLowerCase().contains('selesai diambil'),
    );
  }

  Future<void> showFromModel(NotificationModel notification) async {
    final key = _keyFor(
      id: notification.id,
      title: notification.title,
      referenceId: notification.referenceId,
      type: notification.type.name,
    );
    if (!_shouldShow(key)) return;

    final targets = _resolveTargets(
      type: _typeToBackend(notification.type),
      referenceId: notification.referenceId,
    );

    await _present(
      title: notification.title,
      body: notification.body,
      orderId: targets.orderId,
      queueId: targets.queueId,
      complaintId: targets.complaintId,
      paymentSuccess: notification.title.toLowerCase().contains('pembayaran berhasil'),
      isQueueReady: notification.type == NotificationType.queueReady,
      isCompleted: notification.body.toLowerCase().contains('selesai'),
    );
  }

  Future<void> showPaymentSuccess({
    required String orderId,
    required String title,
    required String body,
    String? queueId,
    String? queueNumber,
    String? orderNumber,
  }) async {
    final key = _keyFor(id: null, title: title, referenceId: orderId, type: 'PAYMENT');
    if (!_shouldShow(key)) return;

    await _present(
      title: title,
      body: body,
      orderId: orderId,
      queueId: queueId,
      queueNumber: queueNumber,
      orderNumber: orderNumber,
      paymentSuccess: true,
    );
  }

  Future<void> showQueueEvent({
    required String title,
    required String body,
    required String queueNumber,
    required bool isReady,
    String? orderId,
    String? queueId,
    String? orderNumber,
  }) async {
    final key = _keyFor(
      id: null,
      title: title,
      referenceId: orderId ?? queueId ?? queueNumber,
      type: isReady ? 'QUEUE_READY' : 'QUEUE_CALLED',
    );
    if (!_shouldShow(key)) return;

    await _present(
      title: title,
      body: body,
      orderId: orderId,
      queueId: queueId,
      queueNumber: queueNumber,
      orderNumber: orderNumber,
      isQueueReady: isReady,
    );
  }

  Future<void> showOrderStatus({
    required String orderId,
    required String title,
    required String body,
  }) async {
    final key = _keyFor(id: null, title: title, referenceId: orderId, type: 'ORDER_STATUS');
    if (!_shouldShow(key)) return;

    await _present(title: title, body: body, orderId: orderId);
  }

  Future<void> showOrderCompleted({
    required String orderId,
    required String title,
    required String body,
    String? orderNumber,
  }) async {
    final key = _keyFor(id: null, title: title, referenceId: orderId, type: 'COMPLETED');
    if (!_shouldShow(key)) return;

    await _present(
      title: title,
      body: body,
      orderId: orderId,
      orderNumber: orderNumber,
      isCompleted: true,
    );
  }

  Future<void> showComplaint({
    required String complaintId,
    required String title,
    required String body,
  }) async {
    final key = _keyFor(id: null, title: title, referenceId: complaintId, type: 'COMPLAINT');
    if (!_shouldShow(key)) return;

    await _present(title: title, body: body, complaintId: complaintId);
  }

  ({String? orderId, String? queueId, String? complaintId}) _resolveTargets({
    required String type,
    String? referenceId,
    Map<String, dynamic>? data,
  }) {
    switch (type) {
      case 'QUEUE_READY':
        return (orderId: data?['orderId']?.toString(), queueId: referenceId, complaintId: null);
      case 'ORDER_STATUS':
        return (orderId: referenceId, queueId: data?['queueId']?.toString(), complaintId: null);
      case 'COMPLAINT':
        return (orderId: null, queueId: null, complaintId: referenceId);
      default:
        return (orderId: referenceId, queueId: null, complaintId: null);
    }
  }

  String _typeToBackend(NotificationType type) {
    switch (type) {
      case NotificationType.queueReady:
        return 'QUEUE_READY';
      case NotificationType.orderStatus:
        return 'ORDER_STATUS';
      case NotificationType.complaint:
        return 'COMPLAINT';
      case NotificationType.promo:
        return 'PROMO';
      case NotificationType.chat:
        return 'CHAT';
    }
  }

  Future<void> _present({
    required String title,
    required String body,
    String? orderId,
    String? queueId,
    String? complaintId,
    String? queueNumber,
    String? orderNumber,
    bool isQueueReady = false,
    bool paymentSuccess = false,
    bool isCompleted = false,
  }) async {
    void onTap() {
      _tapHandler?.call(orderId: orderId, queueId: queueId, complaintId: complaintId);
    }

    _bannerHandler?.call(title: title, body: body, onTap: onTap);

    final push = PushNotificationService.instance;
    if (!push.isSupported) return;

    await push.ensurePermission();

    if (complaintId != null) {
      await push.showComplaintUpdate(complaintId: complaintId, title: title, body: body);
      return;
    }

    if (paymentSuccess && orderId != null) {
      await push.showPaymentSuccess(
        orderId: orderId,
        title: title,
        body: body,
        queueId: queueId,
        queueNumber: queueNumber,
        orderNumber: orderNumber,
      );
      return;
    }

    if (isCompleted && orderId != null) {
      await push.showOrderCompleted(
        orderId: orderId,
        orderNumber: orderNumber,
        title: title,
        body: body,
      );
      return;
    }

    if (isQueueReady) {
      await push.showQueueReady(
        queueNumber: queueNumber ?? '-',
        orderId: orderId,
        queueId: queueId,
        orderNumber: orderNumber,
        title: title,
        body: body,
      );
      return;
    }

    if (queueId != null && !isQueueReady && orderId == null) {
      await push.showQueueCalled(
        queueNumber: queueNumber ?? '-',
        orderId: orderId,
        queueId: queueId,
        orderNumber: orderNumber,
        title: title,
        body: body,
      );
      return;
    }

    if (orderId != null) {
      await push.showOrderStatusUpdate(orderId: orderId, title: title, body: body);
    }
  }
}
