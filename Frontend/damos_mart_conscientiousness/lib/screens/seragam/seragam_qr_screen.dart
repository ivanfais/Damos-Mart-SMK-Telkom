import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';

class SeragamQrScreen extends StatelessWidget {
  final OrderModel order;
  const SeragamQrScreen({super.key, required this.order});

  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _green10 = Color(0xFFDCF5E0);

  String get _paymentStatusLabel =>
      order.paymentStatus == PaymentStatus.paid ? 'Lunas' : 'Belum Dibayar';

  ({String label, IconData icon, Color bg, Color fg}) get _statusInfo {
    switch (order.status) {
      case OrderStatus.paid:
        return (label: 'Pesanan Dibayar', icon: Icons.check_circle, bg: _green10, fg: _primary);
      case OrderStatus.preparing:
      case OrderStatus.inProduction:
        return (label: 'Dalam Produksi', icon: Icons.autorenew, bg: _green10, fg: _dark);
      case OrderStatus.ready:
        return (label: 'Pesanan Siap Diambil', icon: Icons.check_circle, bg: _primary, fg: Colors.white);
      case OrderStatus.completed:
        return (label: 'Pesanan Selesai', icon: Icons.task_alt, bg: const Color(0xFFEEEEEE), fg: _grey);
      default:
        return (label: 'Menunggu Pembayaran', icon: Icons.hourglass_empty, bg: const Color(0xFFFFF8E1), fg: const Color(0xFF8D6E00));
    }
  }

  String get _subtitle {
    switch (order.status) {
      case OrderStatus.paid:         return 'Pesanan Anda telah dibayar';
      case OrderStatus.preparing:
      case OrderStatus.inProduction: return 'Pesanan Anda dalam produksi';
      case OrderStatus.ready:        return 'Pesanan Anda siap diambil';
      case OrderStatus.completed:    return 'Pesanan Anda telah selesai';
      default:                       return 'Pesanan Anda';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _primary,
            padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Kembali',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Detail Antrean',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: _dark)),
                  const SizedBox(height: 4),
                  Text(_subtitle,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _green10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _dark, width: 1.5),
                          ),
                          child: QrImageView(
                            data: 'DAMOS-MART-PO|${order.orderNumber}|${order.id}',
                            version: QrVersions.auto,
                            size: 200,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF888888)),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF888888)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tunjukkan kode QR ini ke kasir untuk\nmengambil pesanan PO Seragam Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontStyle: FontStyle.italic, color: _grey, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _row('ID Pesanan', order.orderNumber),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFE0E0E0)),
                              const SizedBox(height: 8),
                              _row('Status Pembayaran', _paymentStatusLabel),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFE0E0E0)),
                              const SizedBox(height: 8),
                              _row('Waktu Transaksi',
                                  DateFormatter.format(order.paidAt ?? order.createdAt)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status badge — sesuai status order saat ini
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Icon(status.icon, size: 28, color: status.fg),
                        const SizedBox(height: 8),
                        Text(status.label,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: status.fg)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _grey)),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
      ],
    );
  }
}
