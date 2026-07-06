import 'package:equatable/equatable.dart';

enum ComplaintStatus { open, inProgress, resolved, rejected }

enum ComplaintCategory { product, service, order, queue, other }

class ComplaintModel extends Equatable {
  final String id;
  final String subject;
  final String description;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const ComplaintModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    this.resolvedAt,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: _parseCategory(_readString(json, 'category')),
      status: _parseStatus(_readString(json, 'status')),
      adminResponse: _readString(json, 'adminResponse', 'admin_response'),
      respondedAt: _parseDate(_readDynamic(json, 'respondedAt', 'responded_at')),
      resolvedAt: _parseDate(_readDynamic(json, 'resolvedAt', 'resolved_at')),
      createdAt: _parseDate(_readDynamic(json, 'createdAt', 'created_at')) ?? DateTime.now(),
    );
  }

  static String? _readString(Map<String, dynamic> json, String key, [String? altKey]) {
    final value = json[key] ?? (altKey != null ? json[altKey] : null);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static dynamic _readDynamic(Map<String, dynamic> json, String key, String altKey) {
    return json[key] ?? json[altKey];
  }

  static ComplaintCategory _parseCategory(String? value) {
    switch (value?.toUpperCase()) {
      case 'PRODUCT':
        return ComplaintCategory.product;
      case 'SERVICE':
        return ComplaintCategory.service;
      case 'ORDER':
        return ComplaintCategory.order;
      case 'QUEUE':
        return ComplaintCategory.queue;
      default:
        return ComplaintCategory.other;
    }
  }

  static ComplaintStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'OPEN':
        return ComplaintStatus.open;
      case 'IN_PROGRESS':
        return ComplaintStatus.inProgress;
      case 'RESOLVED':
        return ComplaintStatus.resolved;
      case 'REJECTED':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.open;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String get ticketNumber {
    final numeric = id.hashCode.abs() % 10000;
    return '#KM-${numeric.toString().padLeft(4, '0')}';
  }

  String? get adminResponseText {
    final text = adminResponse?.trim();
    return text != null && text.isNotEmpty ? text : null;
  }

  @override
  List<Object?> get props => [
        id,
        subject,
        description,
        status,
        adminResponse,
        respondedAt,
        resolvedAt,
        createdAt,
      ];
}
