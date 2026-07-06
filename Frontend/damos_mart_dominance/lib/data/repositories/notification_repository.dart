import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final DioClient _client;

  NotificationRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get(ApiConfig.notifications);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.put(ApiConfig.readNotification(id));
  }

  Future<void> markAllAsRead() async {
    await _client.put(ApiConfig.readAllNotifications);
  }
}
