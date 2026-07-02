import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_brand_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color red = Color(0xFFD42427);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color amberBg = Color(0xFFFFF8E1);
  static const Color amberBorder = Color(0xFFFFE082);
  static const Color amberText = Color(0xFFE65100);
}

class PickupTicketScreen extends StatefulWidget {
  final String orderId;

  const PickupTicketScreen({super.key, required this.orderId});

  @override
  State<PickupTicketScreen> createState() => _PickupTicketScreenState();
}

class _PickupTicketScreenState extends State<PickupTicketScreen> {
  bool _isCashUnpaid(OrderModel order) {
    return order.paymentMethod == PaymentMethod.cashAtCounter &&
        order.paymentStatus == PaymentStatus.unpaid;
  }

  ({String title, String subtitle, IconData icon, Color color}) _paymentHeadline(OrderModel order) {
    if (_isCashUnpaid(order)) {
      return (
        title: 'Belum Bayar',
        subtitle: 'Pesanan dibuat. Selesaikan pembayaran tunai di kasir saat mengambil antrean.',
        icon: Icons.payments_outlined,
        color: _Ds.amberText,
      );
    }
    if (order.paymentStatus == PaymentStatus.paid) {
      return (
        title: 'Pembayaran Berhasil',
        subtitle: 'Pesanan Anda sedang diproses',
        icon: Icons.check,
        color: _Ds.primary,
      );
    }
    if (order.paymentStatus == PaymentStatus.failed) {
      return (
        title: 'Pembayaran Gagal',
        subtitle: 'Silakan ulangi pembayaran atau hubungi petugas',
        icon: Icons.close,
        color: _Ds.red,
      );
    }
    return (
      title: 'Belum Bayar',
      subtitle: 'Menunggu pembayaran di kasir',
      icon: Icons.schedule,
      color: _Ds.red,
    );
  }

  String _paymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Sudah Dibayar';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.unpaid:
        return 'Belum Bayar';
    }
  }

  String _paymentMethodLabel(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.cashAtCounter:
        return 'Bayar di Kasir';
      case null:
        return '-';
    }
  }

  String _qrCaption(OrderModel order) {
    if (_isCashUnpaid(order)) {
      return 'Tunjukkan kode QR dan nomor antrean ke kasir.\nBayar tunai saat mengambil antrean.';
    }
    return 'Tunjukkan kode QR ini ke kasir untuk\nmengambil pesanan Anda';
  }

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  String _productCountLabel(int totalQuantity) {
    return '$totalQuantity Barang';
  }

  Widget _buildInfoStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: _Ds.textSecondary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: _Ds.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueNumberCard(String queueNumber) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        children: [
          const Text(
            'NOMOR ANTREAN',
            style: TextStyle(
              fontSize: 13,
              color: _Ds.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            queueNumber,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: _Ds.red,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        children: [
          QrImageView(
            data: order.id,
            version: QrVersions.auto,
            size: 120,
            gapless: true,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _Ds.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _Ds.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _qrCaption(order),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentInfoCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.amberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: _Ds.amberText),
              SizedBox(width: 8),
              Text(
                'Cara Pembayaran di Kasir',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _Ds.amberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentStep('1', 'Datang ke kasir Damos Mart dengan tiket ini'),
          const SizedBox(height: 8),
          _buildPaymentStep('2', 'Tunjukkan nomor antrean dan kode QR ke petugas'),
          const SizedBox(height: 8),
          _buildPaymentStep('3', 'Bayar tunai di kasir sebesar:'),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text(
              CurrencyFormatter.format(order.total),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Ds.amberText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPaymentStep('4', 'Setelah dibayar, pesanan akan diproses dan siap diambil'),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _Ds.amberText,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: _Ds.textPrimary, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    final queueNumber = order.queueNumber ?? order.orderNumber;
    final totalQuantity = order.orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final orderTime = order.paidAt ?? order.createdAt;
    final headline = _paymentHeadline(order);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: headline.color,
                shape: BoxShape.circle,
              ),
              child: Icon(headline.icon, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            headline.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: headline.color),
          ),
          const SizedBox(height: 6),
          Text(
            headline.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildQueueNumberCard(queueNumber),
          if (_isCashUnpaid(order)) ...[
            const SizedBox(height: 16),
            _buildCashPaymentInfoCard(order),
          ],
          const SizedBox(height: 16),
          _buildQrCard(order),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoStatCard(
                icon: Icons.access_time_outlined,
                label: 'Estimasi Tunggu',
                value: '10-15 Menit',
              ),
              const SizedBox(width: 12),
              _buildInfoStatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Produk',
                value: _productCountLabel(totalQuantity),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _Ds.borderLight, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Detail Pengambilan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Lokasi Toko', 'Damos Mart'),
          _buildDetailRow('Metode Pembayaran', _paymentMethodLabel(order.paymentMethod)),
          _buildDetailRow('Waktu Pesanan', DateFormatter.formatWeekdayTime(orderTime)),
          _buildDetailRow('Status Pembayaran', _paymentStatusLabel(order.paymentStatus)),
          if (_isCashUnpaid(order))
            _buildDetailRow('Total Tagihan', CurrencyFormatter.format(order.total)),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Selesai & Simpan Tiket',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollPage(List<Widget> children) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosBrandHeader(showTagline: false),
          ...children,
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return _buildScrollPage(
      const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 8),
              LoadingShimmer(width: 64, height: 64, borderRadius: 32),
              SizedBox(height: 16),
              LoadingShimmer(width: 220, height: 28, borderRadius: 8),
              SizedBox(height: 8),
              LoadingShimmer(width: 180, height: 14, borderRadius: 6),
              SizedBox(height: 24),
              LoadingShimmer(width: double.infinity, height: 120, borderRadius: 14),
              SizedBox(height: 16),
              LoadingShimmer(width: double.infinity, height: 200, borderRadius: 14),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: LoadingShimmer(width: double.infinity, height: 110, borderRadius: 12)),
                  SizedBox(width: 12),
                  Expanded(child: LoadingShimmer(width: double.infinity, height: 110, borderRadius: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgLight,
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return _buildShimmerLoading();
          }

          if (state is OrderError) {
            return _buildScrollPage([
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<OrderCubit>().loadOrderDetail(widget.orderId),
                ),
              ),
            ]);
          }

          if (state is OrderDetailLoaded) {
            return _buildScrollPage([_buildContent(state.order)]);
          }

          return _buildScrollPage([
            const SizedBox(
              height: 240,
              child: Center(child: Text('Memuat tiket pengambilan...')),
            ),
          ]);
        },
      ),
    );
  }
}
