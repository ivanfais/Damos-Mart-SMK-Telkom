import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/api_config.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();

  SocketService._internal();

  IO.Socket? _queueSocket;
  IO.Socket? _chatSocket;
  String? _userId;
  String? _activeChatRoomId;

  IO.OptionBuilder get _socketOptions => IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect();

  void init(String userId) {
    _userId = userId;
    _ensureQueueSocket();
    _ensureChatSocket();
  }

  void _ensureQueueSocket() {
    if (_queueSocket == null) {
      _queueSocket = IO.io('${ApiConfig.wsUrl}/queues', _socketOptions.build());

      _queueSocket!.onConnect((_) {
        if (_userId != null) {
          _queueSocket!.emit('queue:subscribe', {'userId': _userId});
        }
      });
    } else if (_queueSocket!.disconnected) {
      _queueSocket!.connect();
    } else if (_userId != null) {
      _queueSocket!.emit('queue:subscribe', {'userId': _userId});
    }
  }

  void _ensureChatSocket() {
    if (_chatSocket == null) {
      _chatSocket = IO.io('${ApiConfig.wsUrl}/chat', _socketOptions.build());

      _chatSocket!.onConnect((_) {
        if (_activeChatRoomId != null) {
          _chatSocket!.emit('chat:join', {'roomId': _activeChatRoomId});
        }
      });
    } else if (_chatSocket!.disconnected) {
      _chatSocket!.connect();
    }
  }

  void onQueueUpdated(void Function(dynamic) callback) {
    _ensureQueueSocket();
    _queueSocket!.on('queue:updated', callback);
  }

  void onQueueCalled(void Function(dynamic) callback) {
    _ensureQueueSocket();
    _queueSocket!.on('queue:called', callback);
  }

  void onQueueReady(void Function(dynamic) callback) {
    _ensureQueueSocket();
    _queueSocket!.on('queue:ready', callback);
  }

  void offQueueUpdated(void Function(dynamic) callback) {
    _queueSocket?.off('queue:updated', callback);
  }

  void offQueueCalled(void Function(dynamic) callback) {
    _queueSocket?.off('queue:called', callback);
  }

  void offQueueReady(void Function(dynamic) callback) {
    _queueSocket?.off('queue:ready', callback);
  }

  void onOrderStatusUpdated(void Function(dynamic) callback) {
    _ensureQueueSocket();
    _queueSocket!.on('order:status_updated', callback);
  }

  void offOrderStatusUpdated(void Function(dynamic) callback) {
    _queueSocket?.off('order:status_updated', callback);
  }

  void joinChat(String roomId) {
    _activeChatRoomId = roomId;
    _ensureChatSocket();
    if (_chatSocket!.connected) {
      _chatSocket!.emit('chat:join', {'roomId': roomId});
    }
  }

  void sendChatMessage(String roomId, String message, String senderId) {
    _chatSocket?.emit('chat:send', {
      'roomId': roomId,
      'message': message,
      'senderId': senderId,
    });
  }

  void sendTypingIndicator(String roomId, String userId, bool isTyping) {
    _chatSocket?.emit('chat:typing', {
      'roomId': roomId,
      'userId': userId,
      'isTyping': isTyping,
    });
  }

  void onChatMessage(void Function(dynamic) callback) {
    _ensureChatSocket();
    _chatSocket!.on('chat:message', callback);
  }

  void offChatMessage(void Function(dynamic) callback) {
    _chatSocket?.off('chat:message', callback);
  }

  void onChatTyping(void Function(dynamic) callback) {
    _ensureChatSocket();
    _chatSocket!.on('chat:typing', callback);
  }

  void offChatTyping(void Function(dynamic) callback) {
    _chatSocket?.off('chat:typing', callback);
  }

  void leaveChat(String roomId) {
    _chatSocket?.emit('chat:leave', {'roomId': roomId});
    if (_activeChatRoomId == roomId) {
      _activeChatRoomId = null;
    }
  }

  void disconnect() {
    _queueSocket?.disconnect();
    _queueSocket = null;
    _chatSocket?.disconnect();
    _chatSocket = null;
    _userId = null;
    _activeChatRoomId = null;
  }
}
