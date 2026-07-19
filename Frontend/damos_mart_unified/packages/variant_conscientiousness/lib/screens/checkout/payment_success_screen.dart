import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart' show OrderModel, PaymentStatus, PaymentMethod;
import '../seragam/seragam_order_tracking_screen.dart' show SeragamOrderDetailScreen;
import '../seragam/seragam_virtual_account_screen.dart' show SeragamOrderTracker;

class PaymentSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const PaymentSuccessScreen({super.key, required this.order});

  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _green10  = Color(0xFFDCF5E0);
  static const Color _yellow   = Color(0xFFF5DA42);

  bool get _isCashUnpaid =>
      order.paymentMethod == PaymentMethod.cashAtCounter && order.paymentStatus != PaymentStatus.paid;

  String get _methodLabel =>
      order.paymentMethod == PaymentMethod.cashAtCounter ? 'Bayar di Kasir' : 'QRIS';

  bool get _isSeragamOrder {
    final notes = order.notes?.toLowerCase() ?? '';
    return notes.contains('seragam') || notes.contains('transfer bank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // App bar
          Container(
            color: _primary,
            padding: EdgeInsets.fromLTRB(
                4, MediaQuery.of(context).padding.top + 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go(_isSeragamOrder ? '/seragam' : '/home'),
                ),
                Text(_isSeragamOrder ? 'Kembali Ke Katalog' : 'Kembali Ke Beranda',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _green10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Status icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _isCashUnpaid ? _yellow : _primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                          _isCashUnpaid ? Icons.error_outline : Icons.check_circle_outline,
                          color: _isCashUnpaid ? _dark : Colors.white,
                          size: 44),
                    ),
                    const SizedBox(height: 20),

                    Text(_isCashUnpaid ? 'Pembayaran Belum lunas' : 'Pembayaran Berhasil',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111))),
                    const SizedBox(height: 10),

                    const Text(
                      'Terima kasih atas pesanan Anda.\nTransaksi telah kami terima dan akan\nsegera diproses oleh tim kami.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Detail card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _row('ID Pesanan', order.orderNumber),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 10),
                          _row('Metode', _methodLabel),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 10),
                          _row('Waktu Transaksi',
                              DateFormatter.format(order.paidAt ?? order.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lihat Detail Antrean button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isSeragamOrder) {
                            SeragamOrderTracker.addOrder(order);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SeragamOrderDetailScreen(order: order),
                              ),
                            );
                            return;
                          }
                          final queueId = order.queueId;
                          if (queueId != null && queueId.isNotEmpty) {
                            context.push('/queue/$queueId');
                          } else {
                            context.go('/queue');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: _primary.withOpacity(0.6), width: 2),
                          ),
                        ),
                        child: Text(
                            _isSeragamOrder ? 'Cek Status Pesanan' : 'Lihat Detail Antrean',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
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
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: _grey)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _dark)),
      ],
    );
  }
}
