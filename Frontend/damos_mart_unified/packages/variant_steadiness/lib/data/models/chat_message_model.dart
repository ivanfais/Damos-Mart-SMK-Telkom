import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, roomId, senderId, message, isRead, createdAt];
}
