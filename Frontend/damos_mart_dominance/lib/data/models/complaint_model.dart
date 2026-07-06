import 'package:equatable/equatable.dart';

class ComplaintOrderSummary extends Equatable {
  const ComplaintOrderSummary({
    required this.id,
    required this.orderNumber,
  });

  final String id;
  final String orderNumber;

  factory ComplaintOrderSummary.fromJson(Map<String, dynamic> json) {
    return ComplaintOrderSummary(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, orderNumber];
}

class ComplaintModel extends Equatable {
  const ComplaintModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.order,
    this.adminResponse,
    this.respondedAt,
    this.resolvedAt,
  });

  final String id;
  final String subject;
  final String description;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? orderId;
  final ComplaintOrderSummary? order;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    ComplaintOrderSummary? orderSummary;
    if (json['order'] is Map<String, dynamic>) {
      orderSummary =
          ComplaintOrderSummary.fromJson(json['order'] as Map<String, dynamic>);
    }

    return ComplaintModel(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      orderId: json['orderId'] as String?,
      order: orderSummary,
      adminResponse: json['adminResponse'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String).toLocal()
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String).toLocal()
          : null,
    );
  }

  String get displayTicketNumber {
    final year = createdAt.year;
    final numeric = id.hashCode.abs() % 1000;
    return 'CMP-$year-${numeric.toString().padLeft(3, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        subject,
        description,
        category,
        status,
        createdAt,
        orderId,
        order,
        adminResponse,
        respondedAt,
        resolvedAt,
      ];
}
