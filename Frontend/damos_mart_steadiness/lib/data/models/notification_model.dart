import 'package:equatable/equatable.dart';

enum NotificationType { queueReady, orderStatus, promo, chat, complaint }

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
    final rawType = (json['type'] ?? json['notification_type'])?.toString();
    NotificationType parsedType = NotificationType.promo;
    switch (rawType) {
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
      case 'COMPLAINT':
        parsedType = NotificationType.complaint;
        break;
    }

    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw.toLocal();
    } else {
      createdAt = DateTime.now();
    }

    final title = _readString(json, const ['title', 'subject', 'heading']);
    final body = _readString(json, const ['body', 'message', 'content', 'description']);

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      title: title.isNotEmpty ? title : 'Notifikasi',
      body: body,
      type: parsedType,
      referenceId: (json['referenceId'] ?? json['reference_id'])?.toString(),
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: createdAt,
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
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
      case NotificationType.complaint:
        typeStr = 'COMPLAINT';
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
