import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import 'seragam_virtual_account_screen.dart' show SeragamOrderTracker;
import 'seragam_qr_screen.dart';

class SeragamOrderTrackingScreen extends StatelessWidget {
  const SeragamOrderTrackingScreen({super.key});

  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);
  static const Color _green10 = Color(0xFFDCF5E0);

  @override
  Widget build(BuildContext context) {
    final orders = SeragamOrderTracker.orders;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: orders.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _buildOrderCard(context, orders[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/seragam'),
          ),
          const Text('Lacak Pesanan Seragam',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text('Belum ada pesanan seragam',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
          SizedBox(height: 6),
          Text('Pesanan Anda akan muncul di sini\nsetelah melakukan pre-order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF888888), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final item = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final orderDate = DateFormatter.formatShort(order.createdAt);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SeragamOrderDetailScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 64, height: 64,
                color: const Color(0xFFF0F0F0),
                child: item?.imageUrl != null
                    ? Image.network(ApiConfig.imageUrl(item!.imageUrl!), fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)))
                    : const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item?.productName ?? order.orderNumber,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                  Text('Order ID : ${order.orderNumber}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                  Text('Order Date: $orderDate',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _grey),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Status Screen ─────────────────────────────────────────────────
class SeragamOrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const SeragamOrderDetailScreen({super.key, required this.order});

  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _green10 = Color(0xFFDCF5E0);
  static const Color _border  = Color(0xFFCCCCCC);

  int get _step {
    switch (order.status) {
      case OrderStatus.paid:         return 1;
      case OrderStatus.preparing:
      case OrderStatus.inProduction: return 2;
      case OrderStatus.ready:        return 3;
      case OrderStatus.completed:    return 4;
      default:                       return 0;
    }
  }

  static const _steps = [
    _StepInfo('Pesanan Dibayar',  'Pembayaran telah dikonfirmasi.'),
    _StepInfo('Dalam Produksi',   'Dalam proses penjahitan di vendor.'),
    _StepInfo('Siap Diambil',     'Menunggu penyelesaian produksi.'),
    _StepInfo('Selesai',          ''),
  ];

  String _estimasiSelesai() {
    final base = order.paidAt ?? order.createdAt;
    var result = base;
    var added  = 0;
    while (added < 14) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) added++;
    }
    return DateFormatter.formatShort(result);
  }

  @override
  Widget build(BuildContext context) {
    final item = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final step = _step;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // App bar
          Container(
            color: _primary,
            padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Kembali Ke Katalog',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 60, height: 60,
                            color: const Color(0xFFF0F0F0),
                            child: item?.imageUrl != null
                                ? Image.network(ApiConfig.imageUrl(item!.imageUrl!), fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)))
                                : const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item?.productName ?? 'Seragam',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                            Text('Order ID : ${order.orderNumber}',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                            Text('Order Date: ${DateFormatter.formatShort(order.createdAt)}',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _green10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progres Pesanan',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
                        const SizedBox(height: 16),
                        ..._steps.asMap().entries.map((e) {
                          final idx   = e.key;
                          final sInfo = e.value;
                          final done  = step > idx;
                          final curr  = step == idx;
                          final isLast = idx == _steps.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: done ? _primary : Colors.transparent,
                                      border: Border.all(
                                          color: done || curr ? _primary : _grey,
                                          width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: done
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  if (!isLast)
                                    Container(width: 2, height: 40,
                                        color: done ? _primary : const Color(0xFFCCCCCC)),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sInfo.title,
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: done || curr ? FontWeight.w700 : FontWeight.w400,
                                              color: done || curr ? _dark : _grey)),
                                      if (sInfo.subtitle.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(sInfo.subtitle,
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                                        ),
                                      if (!isLast) const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estimasi selesai card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 28, color: _grey),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Selesai',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                            Text(_estimasiSelesai(),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _dark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Pesanan button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SeragamQrScreen(order: order)),
                      ),
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      label: const Text('QR Pesanan',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, size: 16, color: _grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Informasi: Proses produksi memakan waktu maksimal 14 hari kerja sejak pembayaran dikonfirmasi.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey, fontStyle: FontStyle.italic, height: 1.4),
                          ),
                        ),
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
}

class _StepInfo {
  final String title, subtitle;
  const _StepInfo(this.title, this.subtitle);
}
