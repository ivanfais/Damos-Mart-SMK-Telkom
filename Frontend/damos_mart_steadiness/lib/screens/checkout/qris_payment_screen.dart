import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../config/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF3F4F6);
  static const double serviceFee = 500;
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

  int _productCount(OrderModel order) {
    if (order.orderItems.isEmpty) return 1;
    return order.orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double _serviceFee(OrderModel order) {
    final diff = order.total - order.subtotal;
    return diff > 0 ? diff : _Ds.serviceFee;
  }

  double _grandTotal(OrderModel order) {
    if (order.total > order.subtotal) {
      return order.total;
    }
    return order.subtotal + _Ds.serviceFee;
  }

  Future<void> _confirmPayment() async {
    if (_isVerifying || _order == null) return;

    setState(() => _isVerifying = true);
    await context.read<OrderCubit>().payOrder(
          _order!.id,
          paymentMethod: 'QRIS',
        );
  }

  void _handleBack() {
    if (_isVerifying) return;

    PopUpAlert.show(
      context: context,
      title: 'Batalkan Pembayaran?',
      description: 'Pesanan belum dibayar. Kamu bisa melanjutkan pembayaran nanti dari riwayat pesanan.',
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

  Widget _buildTotalCard(OrderModel order) {
    final total = _grandTotal(order);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL BAYAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Ds.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _Ds.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisImage() {
    return Image.asset(
      AppConstants.imageQrisDummy,
      width: double.infinity,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    final productCount = _productCount(order);
    final serviceFee = _serviceFee(order);
    final total = _grandTotal(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal ($productCount Produk)', CurrencyFormatter.format(order.subtotal)),
          const SizedBox(height: 8),
          _summaryRow('Biaya Admin', CurrencyFormatter.format(serviceFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _Ds.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Ds.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _Ds.border,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        'Sudah Bayar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isVerifying ? null : _handleBack,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _Ds.cardBg,
                  foregroundColor: _Ds.primary,
                  side: const BorderSide(color: _Ds.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Column(
      children: [
        const SteadinessAppHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Scan QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _Ds.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan pindai kode di bawah ini menggunakan aplikasi perbankan atau e-wallet Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _Ds.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTotalCard(order),
                const SizedBox(height: 20),
                _buildQrisImage(),
                const SizedBox(height: 20),
                _buildOrderSummary(order),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded && _order == null) {
            setState(() => _order = state.order);
          }

          if (state is OrderDetailLoaded && _isVerifying) {
            context.read<CartCubit>().loadCart();
            final authState = context.read<AuthBloc>().state;
            final userId = authState is Authenticated ? authState.user.id : null;
            context.read<QueueCubit>().loadActiveQueues(userId: userId);
            context.read<NotificationCubit>().loadNotifications();

            final order = state.order;
            if (order.isPreorder) {
              context.go('/checkout/status/${order.id}');
            } else if (order.queueId != null && order.queueId!.isNotEmpty) {
              context.go('/queue/${order.queueId}/qr');
            } else {
              context.go('/checkout/status/${order.id}');
            }
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
            return const Column(
              children: [
                SteadinessAppHeader(),
                Expanded(
                  child: Center(child: CircularProgressIndicator(color: _Ds.primary)),
                ),
              ],
            );
          }

          return _buildContent(order);
        },
      ),
    );
  }
}
