import 'package:equatable/equatable.dart';
import 'order_model.dart';

enum QueueStatus { waiting, preparing, ready, completed, skipped }

class QueueModel extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final String queueNumber;
  final DateTime queueDate;
  final QueueStatus status;
  final int? estimatedWaitMinutes;
  final DateTime? calledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderModel? order;

  const QueueModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.queueNumber,
    required this.queueDate,
    required this.status,
    this.estimatedWaitMinutes,
    this.calledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.order,
  });

  factory QueueModel.fromJson(Map<String, dynamic> json) {
    // QueueStatus mapping
    QueueStatus parsedStatus = QueueStatus.waiting;
    switch (json['status']) {
      case 'WAITING':
        parsedStatus = QueueStatus.waiting;
        break;
      case 'PREPARING':
        parsedStatus = QueueStatus.preparing;
        break;
      case 'READY':
        parsedStatus = QueueStatus.ready;
        break;
      case 'COMPLETED':
        parsedStatus = QueueStatus.completed;
        break;
      case 'SKIPPED':
        parsedStatus = QueueStatus.skipped;
        break;
    }

    return QueueModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      queueNumber: json['queueNumber'] as String,
      queueDate: DateTime.parse(json['queueDate'] as String),
      status: parsedStatus,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      calledAt: json['calledAt'] != null ? DateTime.parse(json['calledAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      order: json['order'] != null ? OrderModel.fromJson(json['order'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr = 'WAITING';
    switch (status) {
      case QueueStatus.waiting:
        statusStr = 'WAITING';
        break;
      case QueueStatus.preparing:
        statusStr = 'PREPARING';
        break;
      case QueueStatus.ready:
        statusStr = 'READY';
        break;
      case QueueStatus.completed:
        statusStr = 'COMPLETED';
        break;
      case QueueStatus.skipped:
        statusStr = 'SKIPPED';
        break;
    }

    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'queueNumber': queueNumber,
      'queueDate': queueDate.toIso8601String(),
      'status': statusStr,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'calledAt': calledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        queueNumber,
        queueDate,
        status,
        estimatedWaitMinutes,
        calledAt,
        completedAt,
        createdAt,
        updatedAt,
        order,
      ];
}
