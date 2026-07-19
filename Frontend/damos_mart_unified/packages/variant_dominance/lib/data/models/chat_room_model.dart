import 'package:equatable/equatable.dart';

class ChatRoomModel extends Equatable {
  final String id;
  final String studentId;
  final String? adminId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const ChatRoomModel({
    required this.id,
    required this.studentId,
    this.adminId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      adminId: json['adminId'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'adminId': adminId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, studentId, adminId, lastMessage, lastMessageAt, createdAt];
}
