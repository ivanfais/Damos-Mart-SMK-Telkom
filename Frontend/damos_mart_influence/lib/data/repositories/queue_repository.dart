import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/queue_model.dart';

class QueueRepository {
  final DioClient _client;

  QueueRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<QueueModel>> getActiveQueues() async {
    final response = await _client.get(ApiConfig.activeQueues);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => QueueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<QueueModel> getQueueDetails(String queueId) async {
    final response = await _client.get(ApiConfig.queueDetail(queueId));
    final data = response.data['data'] as Map<String, dynamic>;
    final queueJson = Map<String, dynamic>.from(data['queue'] as Map<String, dynamic>);
    if (queueJson['order'] == null && data['order'] != null) {
      queueJson['order'] = data['order'];
    }
    return QueueModel.fromJson(queueJson);
  }

  Future<Map<String, dynamic>> getCurrentQueueState() async {
    final response = await _client.get(ApiConfig.currentQueueState);
    return response.data['data'] as Map<String, dynamic>;
  }
}
