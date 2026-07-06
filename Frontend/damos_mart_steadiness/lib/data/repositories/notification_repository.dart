import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final DioClient _client;

  NotificationRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get(ApiConfig.notifications);
    final raw = response.data['data'];
    final List<dynamic> dataList;
    if (raw is List) {
      dataList = raw;
    } else if (raw is Map<String, dynamic> && raw['notifications'] is List) {
      dataList = raw['notifications'] as List;
    } else {
      dataList = const [];
    }
    final notifications = <NotificationModel>[];
    final seenIds = <String>{};
    for (final item in dataList) {
      if (item is! Map) continue;
      try {
        final map = Map<String, dynamic>.from(item);
        final notification = NotificationModel.fromJson(map);
        if (notification.id.isEmpty) continue;
        if (notification.title.trim().isEmpty && notification.body.trim().isEmpty) {
          continue;
        }
        if (seenIds.add(notification.id)) {
          notifications.add(notification);
        }
      } catch (_) {}
    }
    return notifications;
  }

  Future<void> markAsRead(String id) async {
    await _client.put(ApiConfig.readNotification(id));
  }

  Future<void> markAllAsRead() async {
    await _client.put(ApiConfig.readAllNotifications);
  }
}
