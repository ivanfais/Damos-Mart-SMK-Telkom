import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/api_config.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();

  SocketService._internal();

  IO.Socket? _queueSocket;
  IO.Socket? _chatSocket;
  String? _userId;

  void init(String userId) {
    _userId = userId;
    
    // Initialize queues socket
    if (_queueSocket == null) {
      _queueSocket = IO.io(
        '${ApiConfig.wsUrl}/queues',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _queueSocket!.onConnect((_) {
        print('🔌 Connected to /queues namespace');
        if (_userId != null) {
          _queueSocket!.emit('queue:subscribe', {'userId': _userId});
        }
      });

      _queueSocket!.onDisconnect((_) {
        print('🔌 Disconnected from /queues namespace');
      });
    } else {
      if (_queueSocket!.disconnected) {
        _queueSocket!.connect();
      } else if (_userId != null) {
        _queueSocket!.emit('queue:subscribe', {'userId': _userId});
      }
    }
  }

  // Registers callback for queue updates
  void onQueueUpdated(void Function(dynamic) callback) {
    _queueSocket?.on('queue:updated', callback);
  }

  // Registers callback for queue called
  void onQueueCalled(void Function(dynamic) callback) {
    _queueSocket?.on('queue:called', callback);
  }

  // Registers callback for queue ready
  void onQueueReady(void Function(dynamic) callback) {
    _queueSocket?.on('queue:ready', callback);
  }

  // --- CHAT LOGIC ---
  void joinChat(String roomId) {
    if (_chatSocket == null) {
      _chatSocket = IO.io(
        '${ApiConfig.wsUrl}/chat',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _chatSocket!.onConnect((_) {
        print('🔌 Connected to /chat namespace');
        _chatSocket!.emit('chat:join', {'roomId': roomId});
      });
    } else {
      if (_chatSocket!.disconnected) {
        _chatSocket!.connect();
      }
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
    _chatSocket?.on('chat:message', callback);
  }

  void onChatTyping(void Function(dynamic) callback) {
    _chatSocket?.on('chat:typing', callback);
  }

  void leaveChat(String roomId) {
    _chatSocket?.emit('chat:leave', {'roomId': roomId});
  }

  void disconnect() {
    _queueSocket?.disconnect();
    _queueSocket = null;
    _chatSocket?.disconnect();
    _chatSocket = null;
    _userId = null;
  }
}
