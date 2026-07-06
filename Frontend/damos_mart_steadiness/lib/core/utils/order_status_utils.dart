import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';

class OrderStatusUtils {
  OrderStatusUtils._();

  /// Indeks langkah aktif: 0=Pembayaran Berhasil … 3=Selesai.
  static int activeStepIndex({
    required OrderModel order,
    QueueStatus? queueStatus,
  }) {
    if (order.status == OrderStatus.completed || queueStatus == QueueStatus.completed) {
      return 3;
    }
    if (order.status == OrderStatus.ready || queueStatus == QueueStatus.ready) {
      return 2;
    }
    if (order.status == OrderStatus.preparing ||
        order.status == OrderStatus.inProduction ||
        order.status == OrderStatus.paid ||
        order.paymentStatus == PaymentStatus.paid) {
      return 1;
    }
    return 0;
  }

  static String infoMessage({
    required OrderModel order,
    required int activeStep,
  }) {
    if (order.isPreorder) {
      switch (activeStep) {
        case 0:
          return 'Menunggu konfirmasi pembayaran pre-order Anda.';
        case 1:
          return 'Pre-order sedang diproses. Estimasi produksi sesuai ketentuan pre-order.';
        case 2:
          return 'Pre-order siap diambil. Tunjukkan QR pengambilan kepada petugas koperasi.';
        case 3:
          return 'Pre-order telah selesai. Terima kasih telah berbelanja!';
        default:
          return 'Pesanan sedang diproses.';
      }
    }

    switch (activeStep) {
      case 0:
        return 'Menunggu konfirmasi pembayaran pesanan Anda.';
      case 1:
        return 'Pesanan sedang disiapkan oleh petugas koperasi.';
      case 2:
        return 'Pesanan siap diambil. Tunjukkan QR pengambilan kepada petugas koperasi.';
      case 3:
        return 'Pesanan telah selesai. Terima kasih telah berbelanja!';
      default:
        return 'Pesanan sedang diproses.';
    }
  }
}
