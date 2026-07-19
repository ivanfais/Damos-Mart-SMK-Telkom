import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../theme/damos_dominance_colors.dart';

class DamosActiveOrderCard extends StatelessWidget {
  final QueueModel queue;
  final VoidCallback onTapDetail;

  const DamosActiveOrderCard({
    super.key,
    required this.queue,
    required this.onTapDetail,
  });

  String get _orderNumber =>
      queue.order?.orderNumber ?? 'ORD-${queue.orderId.substring(0, 8).toUpperCase()}';

  String get _queueLabel {
    final number = queue.queueNumber;
    if (number.startsWith('#')) return number;
    final digits = RegExp(r'(\d+)').firstMatch(number)?.group(1);
    if (digits != null) return '#${digits.padLeft(3, '0')}';
    return '#$number';
  }

  ({String badge, String subtitle, Color badgeBg, Color badgeFg}) _resolveStatus() {
    final order = queue.order;

    if (order != null) {
      if (order.status == OrderStatus.pending &&
          order.paymentStatus == PaymentStatus.unpaid) {
        return (
          badge: 'Belum Bayar',
          subtitle: 'Segera selesaikan pembayaran di kasir',
          badgeBg: const Color(0xFFFFEBEE),
          badgeFg: DamosDominanceColors.error,
        );
      }

      if (order.status == OrderStatus.ready || queue.status == QueueStatus.ready) {
        return (
          badge: 'Siap Ambil',
          subtitle: 'Produk siap diambil di koperasi',
          badgeBg: const Color(0xFFE8F5E9),
          badgeFg: DamosDominanceColors.primary,
        );
      }

      if (order.status == OrderStatus.paid ||
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.inProduction) {
        final subtitle = queue.status == QueueStatus.preparing
            ? 'Pesanan sedang disiapkan petugas'
            : order.isPreorder
                ? 'Pesanan PO sedang diproses'
                : 'Pesanan dalam antrian koperasi';
        return (
          badge: 'Diproses',
          subtitle: subtitle,
          badgeBg: const Color(0xFFFFF3E0),
          badgeFg: const Color(0xFFE65100),
        );
      }
    }

    switch (queue.status) {
      case QueueStatus.ready:
        return (
          badge: 'Siap Ambil',
          subtitle: 'Produk siap diambil di koperasi',
          badgeBg: const Color(0xFFE8F5E9),
          badgeFg: DamosDominanceColors.primary,
        );
      case QueueStatus.preparing:
        return (
          badge: 'Diproses',
          subtitle: 'Pesanan sedang disiapkan petugas',
          badgeBg: const Color(0xFFFFF3E0),
          badgeFg: const Color(0xFFE65100),
        );
      case QueueStatus.waiting:
        return (
          badge: 'Diproses',
          subtitle: 'Pesanan dalam antrian koperasi',
          badgeBg: const Color(0xFFFFF3E0),
          badgeFg: const Color(0xFFE65100),
        );
      case QueueStatus.completed:
        return (
          badge: 'Selesai',
          subtitle: 'Pesanan telah selesai',
          badgeBg: const Color(0xFFE8F5E9),
          badgeFg: DamosDominanceColors.primary,
        );
      case QueueStatus.skipped:
        return (
          badge: 'Terlewat',
          subtitle: 'Antrian terlewat, hubungi petugas',
          badgeBg: const Color(0xFFFFEBEE),
          badgeFg: DamosDominanceColors.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: DamosDominanceColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: DamosDominanceColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pesanan Aktif',
                  style: TextStyle(
                    color: DamosDominanceColors.textOnPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _orderNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: DamosDominanceColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: DamosDominanceColors.textPrimary,
                              ),
                              children: [
                                const TextSpan(text: 'Nomor Antrian: '),
                                TextSpan(
                                  text: _queueLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DamosDominanceColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DamosDominanceColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: status.badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTapDetail,
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    'Lihat Detail >',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
