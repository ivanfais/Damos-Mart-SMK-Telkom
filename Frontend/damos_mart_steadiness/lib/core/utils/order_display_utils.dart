import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class OrderDisplayColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color grayLight = Color(0xFFF3F4F6);
  static const Color grayText = Color(0xFF6B7280);
  static const Color redLight = Color(0xFFFEE2E2);
  static const Color redText = Color(0xFFD42427);
}

class OrderDisplayUtils {
  OrderDisplayUtils._();

  /// Badge mockup: Berhasil | Antrean | Dibatalkan
  static ({String label, Color bg, Color text}) statusBadge(OrderModel order) {
    if (order.status == OrderStatus.completed) {
      return (
        label: 'Berhasil',
        bg: OrderDisplayColors.greenLight,
        text: OrderDisplayColors.primary,
      );
    }
    if (order.status == OrderStatus.cancelled) {
      return (
        label: 'Dibatalkan',
        bg: OrderDisplayColors.redLight,
        text: OrderDisplayColors.redText,
      );
    }
    return (
      label: 'Antrean',
      bg: OrderDisplayColors.grayLight,
      text: OrderDisplayColors.grayText,
    );
  }

  static String productName(OrderModel order) {
    if (order.orderItems.isNotEmpty) {
      return order.orderItems.first.productName;
    }
    return 'Pesanan Koperasi';
  }

  static int totalBarang(OrderModel order) {
    return order.orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  static String dateBarangLine(OrderModel order) {
    try {
      final local = order.createdAt.toLocal();
      final date = DateFormat('d MMM yyyy', 'id_ID').format(local);
      final qty = totalBarang(order);
      return '$date • $qty Barang';
    } catch (_) {
      final qty = totalBarang(order);
      return '${order.orderNumber} • $qty Barang';
    }
  }

  static bool canBuyAgain(OrderModel order) {
    return order.status != OrderStatus.cancelled;
  }

  static String detailStatusLabel(OrderModel order) {
    switch (order.status) {
      case OrderStatus.completed:
        return 'Berhasil';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.paid:
        return 'Sudah Dibayar';
      case OrderStatus.preparing:
        return 'Sedang Disiapkan';
      case OrderStatus.inProduction:
        return 'Dalam Produksi';
      case OrderStatus.ready:
        return 'Siap Diambil';
    }
  }

  static ({String label, Color bg, Color text}) detailStatusBadge(OrderModel order) {
    switch (order.status) {
      case OrderStatus.completed:
        return (
          label: 'Berhasil',
          bg: OrderDisplayColors.greenLight,
          text: OrderDisplayColors.primary,
        );
      case OrderStatus.cancelled:
        return (
          label: 'Dibatalkan',
          bg: OrderDisplayColors.redLight,
          text: OrderDisplayColors.redText,
        );
      case OrderStatus.ready:
      case OrderStatus.paid:
      case OrderStatus.preparing:
        return (
          label: detailStatusLabel(order),
          bg: OrderDisplayColors.greenLight,
          text: OrderDisplayColors.primary,
        );
      case OrderStatus.inProduction:
        return (
          label: 'Dalam Produksi',
          bg: const Color(0xFFFFF8E1),
          text: const Color(0xFFF59E0B),
        );
      case OrderStatus.pending:
        return (
          label: 'Menunggu Pembayaran',
          bg: const Color(0xFFFFF8E1),
          text: const Color(0xFFF59E0B),
        );
    }
  }
}
