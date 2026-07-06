import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatRepository {
  final DioClient _client;

  ChatRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ChatRoomModel> getOrCreateRoom() async {
    final response = await _client.get(ApiConfig.chatRoom);
    final data = response.data['data'] as Map<String, dynamic>;
    return ChatRoomModel.fromJson(data);
  }

  Future<List<ChatMessageModel>> getRoomMessages(String roomId, {String? cursor, int limit = 30}) async {
    final queryParams = {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
    final response = await _client.get(
      ApiConfig.chatMessages(roomId),
      queryParameters: queryParams,
    );
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageModel> sendMessage(String roomId, String message) async {
    final response = await _client.post(
      ApiConfig.chatMessages(roomId),
      data: {
        'message': message,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ChatMessageModel.fromJson(data);
  }
}
