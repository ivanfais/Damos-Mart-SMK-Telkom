import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color bgLight = Color(0xFFF5F5F5);
}

class QrisPaymentScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;

  const QrisPaymentScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  bool _isVerifying = false;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    }
  }

  String _displayQueueNumber(OrderModel order) {
    if (order.queueNumber != null && order.queueNumber!.isNotEmpty) {
      return order.queueNumber!;
    }

    final match = RegExp(r'A-(\d+)', caseSensitive: false).firstMatch(order.orderNumber);
    if (match != null) {
      return 'A-${match.group(1)!}';
    }

    return 'A-001';
  }

  String _terminalCode(String queueNumber) {
    final match = RegExp(r'(\d+)$').firstMatch(queueNumber);
    if (match == null) return 'A01';
    return match.group(1)!.padLeft(3, '0');
  }

  String _dummyQrisPayload(OrderModel order) {
    final queueNumber = _displayQueueNumber(order);
    return 'DAMOS-MART|$queueNumber|${order.total.toStringAsFixed(0)}|NMID:ID1023304672596';
  }

  Future<void> _simulateScanPayment() async {
    if (_isVerifying || _order == null) return;

    setState(() => _isVerifying = true);
    await context.read<OrderCubit>().payOrder(
          _order!.id,
          paymentMethod: 'QRIS',
        );
  }

  void _handleClose() {
    PopUpAlert.show(
      context: context,
      title: 'Batalkan Pembayaran?',
      description: 'Pesanan belum dibayar. Anda bisa melanjutkan pembayaran nanti dari riwayat pesanan.',
      confirmText: 'Ya, Keluar',
      cancelText: 'Lanjut Bayar',
      onConfirm: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/cart');
        }
      },
    );
  }

  Widget _buildDummyQrisCode(OrderModel order) {
    final qrData = _dummyQrisPayload(order);

    return GestureDetector(
      onTap: _isVerifying ? null : _simulateScanPayment,
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 220,
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
    );
  }

  Widget _buildSimulateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _simulateScanPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _Ds.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simulasi Scan QRIS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    final queueNumber = _displayQueueNumber(order);
    final terminalCode = _terminalCode(queueNumber);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'NOMOR PESANAN',
            style: TextStyle(
              fontSize: 12,
              color: _Ds.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            queueNumber,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _Ds.primary,
              height: 1,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(order.total),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _Ds.textPrimary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'DAMOS MART ${AppConstants.schoolName.toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _Ds.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'NMID : ID1023304672596',
            style: TextStyle(fontSize: 11, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            terminalCode,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Ds.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _buildDummyQrisCode(order),
          const SizedBox(height: 16),
          const Text(
            'SATU QRIS UNTUK SEMUA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Ds.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cek aplikasi penyelenggara di: www.aspi-qris.id',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: _Ds.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DamosPageHeader(
            title: AppConstants.appName,
            showBackButton: true,
            leadingIcon: Icons.close,
            onBack: () {
              if (!_isVerifying) _handleClose();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                _buildPaymentCard(order),
          const SizedBox(height: 20),
          const Text(
            'Scan QR ini untuk melakukan pembayaran',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _Ds.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mode testing: ketuk QR atau tombol di bawah untuk simulasi scan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _Ds.textSecondary.withValues(alpha: 0.95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimulateButton(),
          if (_isVerifying) ...[
            const SizedBox(height: 14),
            const Text(
              'Memverifikasi pembayaran...',
              style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgLight,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded && _order == null) {
            setState(() => _order = state.order);
          }

          if (state is OrderDetailLoaded && _isVerifying) {
            context.read<CartCubit>().loadCart();
            context.go('/checkout/ticket/${state.order.id}');
          }

          if (state is OrderError && _isVerifying) {
            setState(() => _isVerifying = false);
            PopUpAlert.show(
              context: context,
              title: 'Pembayaran Gagal',
              description: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final order = _order;

          if (order == null) {
            return const Center(
              child: CircularProgressIndicator(color: _Ds.primary),
            );
          }

          return _buildContent(order);
        },
      ),
    );
  }
}
