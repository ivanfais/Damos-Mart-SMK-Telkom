import 'package:equatable/equatable.dart';

enum ComplaintReason { productDamaged, quantityShort, other }

extension ComplaintReasonX on ComplaintReason {
  String get apiValue {
    switch (this) {
      case ComplaintReason.productDamaged:
        return 'PRODUCT_DAMAGED';
      case ComplaintReason.quantityShort:
        return 'QUANTITY_SHORT';
      case ComplaintReason.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case ComplaintReason.productDamaged:
        return 'Produk Rusak/Cacat';
      case ComplaintReason.quantityShort:
        return 'Jumlah Produk Kurang';
      case ComplaintReason.other:
        return 'Lainnya';
    }
  }
}

enum ComplaintStatus { open, inProgress, resolved, rejected }

ComplaintStatus _parseStatus(String? value) {
  switch (value) {
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

class ComplaintModel extends Equatable {
  final String id;
  final String complaintNumber;
  final String? orderId;
  final String? orderNumber;
  final String? productName;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final List<String> photos;
  final DateTime createdAt;

  const ComplaintModel({
    required this.id,
    required this.complaintNumber,
    this.orderId,
    this.orderNumber,
    this.productName,
    required this.subject,
    required this.description,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    this.resolvedAt,
    required this.photos,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    final orderItems = order?['orderItems'] as List?;
    final firstItem = (orderItems != null && orderItems.isNotEmpty) ? orderItems.first as Map<String, dynamic> : null;
    final photoList = json['photos'] as List? ?? [];

    return ComplaintModel(
      id: json['id'] as String,
      complaintNumber: json['complaintNumber'] as String,
      orderId: json['orderId'] as String?,
      orderNumber: order?['orderNumber'] as String?,
      productName: firstItem?['productName'] as String?,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: _parseStatus(json['status'] as String?),
      adminResponse: json['adminResponse'] as String?,
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      photos: photoList
          .map((p) => p is Map ? p['photoUrl'] as String : p as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        complaintNumber,
        orderId,
        orderNumber,
        productName,
        subject,
        description,
        status,
        adminResponse,
        respondedAt,
        resolvedAt,
        photos,
        createdAt,
      ];
}

enum ReturnTimeSlot { breakFirst, breakSecond, schoolEnd }

extension ReturnTimeSlotX on ReturnTimeSlot {
  String get apiValue {
    switch (this) {
      case ReturnTimeSlot.breakFirst:
        return 'BREAK_FIRST';
      case ReturnTimeSlot.breakSecond:
        return 'BREAK_SECOND';
      case ReturnTimeSlot.schoolEnd:
        return 'SCHOOL_END';
    }
  }

  String get label {
    switch (this) {
      case ReturnTimeSlot.breakFirst:
        return 'Istirahat Pertama';
      case ReturnTimeSlot.breakSecond:
        return 'Istirahat Kedua';
      case ReturnTimeSlot.schoolEnd:
        return 'Jam Pulang Sekolah';
    }
  }

  String get timeRange {
    switch (this) {
      case ReturnTimeSlot.breakFirst:
        return '09:30 - 10:30';
      case ReturnTimeSlot.breakSecond:
        return '12:15 - 13:00';
      case ReturnTimeSlot.schoolEnd:
        return '15:30 - 16:30';
    }
  }
}

ReturnTimeSlot _parseTimeSlot(String? value) {
  switch (value) {
    case 'BREAK_SECOND':
      return ReturnTimeSlot.breakSecond;
    case 'SCHOOL_END':
      return ReturnTimeSlot.schoolEnd;
    default:
      return ReturnTimeSlot.breakFirst;
  }
}

class ReturnScheduleModel extends Equatable {
  final String id;
  final String complaintId;
  final String complaintNumber;
  final String? orderNumber;
  final String? productName;
  final ComplaintStatus complaintStatus;
  final DateTime returnDate;
  final ReturnTimeSlot timeSlot;
  final DateTime createdAt;

  const ReturnScheduleModel({
    required this.id,
    required this.complaintId,
    required this.complaintNumber,
    this.orderNumber,
    this.productName,
    required this.complaintStatus,
    required this.returnDate,
    required this.timeSlot,
    required this.createdAt,
  });

  factory ReturnScheduleModel.fromJson(Map<String, dynamic> json) {
    final complaint = json['complaint'] as Map<String, dynamic>?;
    final order = complaint?['order'] as Map<String, dynamic>?;
    final orderItems = order?['orderItems'] as List?;
    final firstItem = (orderItems != null && orderItems.isNotEmpty) ? orderItems.first as Map<String, dynamic> : null;

    return ReturnScheduleModel(
      id: json['id'] as String,
      complaintId: json['complaintId'] as String,
      complaintNumber: complaint?['complaintNumber'] as String? ?? '-',
      orderNumber: order?['orderNumber'] as String?,
      productName: firstItem?['productName'] as String?,
      complaintStatus: _parseStatus(complaint?['status'] as String?),
      returnDate: DateTime.parse(json['returnDate'] as String),
      timeSlot: _parseTimeSlot(json['timeSlot'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, complaintId, complaintNumber, orderNumber, productName, complaintStatus, returnDate, timeSlot, createdAt];
}
