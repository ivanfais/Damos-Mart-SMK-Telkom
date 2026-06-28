import 'package:equatable/equatable.dart';

enum NotificationType { queueReady, orderStatus, promo, chat }

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType = NotificationType.promo;
    switch (json['type']) {
      case 'QUEUE_READY':
        parsedType = NotificationType.queueReady;
        break;
      case 'ORDER_STATUS':
        parsedType = NotificationType.orderStatus;
        break;
      case 'PROMO':
        parsedType = NotificationType.promo;
        break;
      case 'CHAT':
        parsedType = NotificationType.chat;
        break;
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: parsedType,
      referenceId: json['referenceId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr = 'PROMO';
    switch (type) {
      case NotificationType.queueReady:
        typeStr = 'QUEUE_READY';
        break;
      case NotificationType.orderStatus:
        typeStr = 'ORDER_STATUS';
        break;
      case NotificationType.promo:
        typeStr = 'PROMO';
        break;
      case NotificationType.chat:
        typeStr = 'CHAT';
        break;
    }

    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': typeStr,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, title, body, type, referenceId, isRead, createdAt];
}
