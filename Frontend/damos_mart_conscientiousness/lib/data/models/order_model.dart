import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final double productPrice;
  final int quantity;
  final double subtotal;
  final String? imageUrl;

  const OrderItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['imageUrl'] as String?;
    if (imageUrl == null && json['product'] is Map<String, dynamic>) {
      imageUrl = (json['product'] as Map<String, dynamic>)['imageUrl'] as String?;
    }

    return OrderItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      productName: json['productName'] as String,
      variantName: json['variantName'] as String?,
      productPrice: double.tryParse(json['productPrice'].toString()) ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantName': variantName,
      'productPrice': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        variantId,
        productName,
        variantName,
        productPrice,
        quantity,
        subtotal,
        imageUrl,
      ];
}

enum OrderStatus {
  pending,
  paid,
  preparing,
  inProduction,
  ready,
  completed,
  cancelled
}

enum PaymentMethod { qris, cashAtCounter }

enum PaymentStatus { unpaid, paid, failed }

class OrderModel extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final bool isPreorder;
  final double subtotal;
  final double total;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> orderItems;
  final String? queueId; // id of the related queue record (for queue detail navigation)
  final String? queueNumber; // helper for queue mapping if included in orders
  final String? queueStatus; // helper

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.isPreorder,
    required this.subtotal,
    required this.total,
    this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
    this.notes,
    required this.createdAt,
    required this.orderItems,
    this.queueId,
    this.queueNumber,
    this.queueStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Status mapping
    OrderStatus parsedStatus = OrderStatus.pending;
    switch (json['status']) {
      case 'PENDING':
        parsedStatus = OrderStatus.pending;
        break;
      case 'PAID':
        parsedStatus = OrderStatus.paid;
        break;
      case 'PREPARING':
        parsedStatus = OrderStatus.preparing;
        break;
      case 'IN_PRODUCTION':
        parsedStatus = OrderStatus.inProduction;
        break;
      case 'READY':
        parsedStatus = OrderStatus.ready;
        break;
      case 'COMPLETED':
        parsedStatus = OrderStatus.completed;
        break;
      case 'CANCELLED':
        parsedStatus = OrderStatus.cancelled;
        break;
    }

    // Payment method mapping
    PaymentMethod? parsedMethod;
    if (json['paymentMethod'] != null) {
      if (json['paymentMethod'] == 'QRIS') {
        parsedMethod = PaymentMethod.qris;
      } else if (json['paymentMethod'] == 'CASH_AT_COUNTER') {
        parsedMethod = PaymentMethod.cashAtCounter;
      }
    }

    // Payment status mapping
    PaymentStatus parsedPayStatus = PaymentStatus.unpaid;
    switch (json['paymentStatus']) {
      case 'UNPAID':
        parsedPayStatus = PaymentStatus.unpaid;
        break;
      case 'PAID':
        parsedPayStatus = PaymentStatus.paid;
        break;
      case 'FAILED':
        parsedPayStatus = PaymentStatus.failed;
        break;
    }

    // Order items mapping
    List<OrderItemModel> items = [];
    if (json['orderItems'] != null && json['orderItems'] is List) {
      items = (json['orderItems'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    // Extract queue info if included
    String? qId;
    String? qNumber;
    String? qStatus;
    if (json['queue'] != null && json['queue'] is Map) {
      qId = json['queue']['id'] as String?;
      qNumber = json['queue']['queueNumber'] as String?;
      qStatus = json['queue']['status'] as String?;
    }

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: parsedStatus,
      isPreorder: json['isPreorder'] as bool? ?? false,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      paymentMethod: parsedMethod,
      paymentStatus: parsedPayStatus,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      orderItems: items,
      queueId: qId,
      queueNumber: qNumber,
      queueStatus: qStatus,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr = 'PENDING';
    switch (status) {
      case OrderStatus.pending:
        statusStr = 'PENDING';
        break;
      case OrderStatus.paid:
        statusStr = 'PAID';
        break;
      case OrderStatus.preparing:
        statusStr = 'PREPARING';
        break;
      case OrderStatus.inProduction:
        statusStr = 'IN_PRODUCTION';
        break;
      case OrderStatus.ready:
        statusStr = 'READY';
        break;
      case OrderStatus.completed:
        statusStr = 'COMPLETED';
        break;
      case OrderStatus.cancelled:
        statusStr = 'CANCELLED';
        break;
    }

    String payStatusStr = 'UNPAID';
    switch (paymentStatus) {
      case PaymentStatus.unpaid:
        payStatusStr = 'UNPAID';
        break;
      case PaymentStatus.paid:
        payStatusStr = 'PAID';
        break;
      case PaymentStatus.failed:
        payStatusStr = 'FAILED';
        break;
    }

    return {
      'id': id,
      'orderNumber': orderNumber,
      'status': statusStr,
      'isPreorder': isPreorder,
      'subtotal': subtotal,
      'total': total,
      'paymentMethod': paymentMethod == PaymentMethod.qris
          ? 'QRIS'
          : paymentMethod == PaymentMethod.cashAtCounter
              ? 'CASH_AT_COUNTER'
              : null,
      'paymentStatus': payStatusStr,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'orderItems': orderItems.map((i) => i.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        isPreorder,
        subtotal,
        total,
        paymentMethod,
        paymentStatus,
        paidAt,
        notes,
        createdAt,
        orderItems,
        queueId,
        queueNumber,
        queueStatus,
      ];
}
