import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class ReceiptDisplayUtils {
  ReceiptDisplayUtils._();

  static double adminFee(OrderModel order) {
    final fee = order.total - order.subtotal;
    return fee > 0 ? fee : 500;
  }

  static String paymentMethodLabel(OrderModel order) {
    switch (order.paymentMethod) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.cashAtCounter:
        return 'Tunai di Kasir';
      case null:
        return '-';
    }
  }

  static String paymentStatusLabel(OrderModel order) {
    if (order.status == OrderStatus.completed) {
      return 'Lunas';
    }

    if (order.status == OrderStatus.cancelled) {
      return order.paymentStatus == PaymentStatus.paid ? 'Lunas' : 'Belum Bayar';
    }

    if (order.status == OrderStatus.paid ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.inProduction ||
        order.status == OrderStatus.ready) {
      return 'Lunas';
    }

    switch (order.paymentStatus) {
      case PaymentStatus.paid:
        return 'Lunas';
      case PaymentStatus.unpaid:
        return 'Belum Bayar';
      case PaymentStatus.failed:
        return 'Gagal';
    }
  }

  static String orderTypeLabel(OrderModel order) {
    return order.isPreorder ? 'Pre-order' : 'Belanja Reguler';
  }

  static String queueLabel(OrderModel order) {
    final raw = order.queueNumber;
    if (raw == null || raw.isEmpty) return '-';
    return raw.startsWith('#') ? raw : '#$raw';
  }

  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(local);
  }

  static String formatPaidAt(OrderModel order) {
    final paidAt = order.paidAt ?? order.createdAt;
    return formatDateTime(paidAt);
  }

  static String transactionId(OrderModel order) {
    return order.orderNumber;
  }
}
