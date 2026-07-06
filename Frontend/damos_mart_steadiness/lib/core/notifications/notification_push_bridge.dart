import '../../data/models/notification_model.dart';

/// Menyinkronkan notifikasi dari API dengan push lokal (fallback jika socket terlewat).
class NotificationPushBridge {
  NotificationPushBridge._();

  static final NotificationPushBridge instance = NotificationPushBridge._();

  final Set<String> _seenIds = {};
  bool _initialized = false;

  void reset() {
    _seenIds.clear();
    _initialized = false;
  }

  void onNotificationsLoaded(List<NotificationModel> notifications) {
    if (!_initialized) {
      _seenIds.addAll(notifications.map((n) => n.id));
      _initialized = true;
      return;
    }

    for (final notification in notifications) {
      if (notification.id.isEmpty || _seenIds.contains(notification.id)) continue;
      _seenIds.add(notification.id);
      if (notification.isRead) continue;
      onNewNotification?.call(notification);
    }
  }

  void Function(NotificationModel notification)? onNewNotification;
}
