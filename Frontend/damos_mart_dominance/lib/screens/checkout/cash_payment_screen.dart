import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/env.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/pop_up_alert.dart';

class _CashStyle {
  static const double cardRadius = 8;
  static const Color cardBorder = DamosDominanceColors.fieldBorder;
  static const Color waitingBannerBg = Color(0xFFFFF3E0);
  static const Color waitingBannerFg = Color(0xFFE65100);
  static const Color expiredBannerBg = Color(0xFFFFEBEE);
  static const Color expiredBannerFg = Color(0xFFD42427);
  static const Color infoBannerBg = Color(0xFFE8F5E9);
  static const Color infoBannerFg = Color(0xFF2E7D32);

  static const int paymentTimeoutSeconds = 15 * 60;
}

class CashPaymentScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;

  const CashPaymentScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  OrderModel? _order;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _remainingSeconds = _CashStyle.paymentTimeoutSeconds;
  bool _expired = false;
  bool _isVerifying = false;
  bool _isCancelling = false;

  bool get _showDevControls => kDebugMode || Env.isDevelopment;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    }
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_expired || _isVerifying) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _expired || _isVerifying) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _handleTimeout();
        return;
      }

      setState(() => _remainingSeconds -= 1);
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (_expired) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _expired || _isVerifying) return;
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    });
  }

  Future<void> _handleTimeout() async {
    if (_expired || !mounted) return;

    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    setState(() {
      _expired = true;
      _isCancelling = true;
      _remainingSeconds = 0;
    });

    try {
      await context.read<OrderCubit>().cancelOrder(widget.orderId);
    } catch (_) {
      // Tetap tampilkan UI expired meski cancel gagal di backend.
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  int get _safeRemainingSeconds {
    final value = _remainingSeconds;
    if (value < 0) return 0;
    if (value > _CashStyle.paymentTimeoutSeconds) {
      return _CashStyle.paymentTimeoutSeconds;
    }
    return value;
  }

  String get _countdownLabel {
    final total = _safeRemainingSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _queueDisplay(OrderModel order) {
    final number = order.queueNumber;
    if (number == null || number.isEmpty) return '#---';
    return number.startsWith('#') ? number : '#$number';
  }

  Future<void> _simulatePayment() async {
    if (_isVerifying || _expired || _order == null) return;

    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    setState(() => _isVerifying = true);

    await context.read<OrderCubit>().payOrder(
          _order!.id,
          paymentMethod: 'CASH_AT_COUNTER',
        );
  }

  Future<void> _onPaymentSuccess(String orderId) async {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    context.read<CartCubit>().loadCart();
    await PopUpAlert.showPaymentSuccess(
      context: context,
      description: 'Pesananmu sedang diproses.',
    );
    if (!mounted) return;
    context.go('/orders/$orderId');
  }

  Widget _lineDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _CashStyle.cardBorder,
    );
  }

  Widget _buildWaitingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: _CashStyle.waitingBannerBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 20, color: _CashStyle.waitingBannerFg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pembayaran di Kasir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _CashStyle.waitingBannerFg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Segera datang ke Kasir sebelum waktu habis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _CashStyle.waitingBannerFg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CashStyle.expiredBannerBg,
        borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 20, color: _CashStyle.expiredBannerFg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan dibatalkan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _CashStyle.expiredBannerFg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Waktu Pembayaran habis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _CashStyle.expiredBannerFg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
        border: Border.all(color: _CashStyle.cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Nomor Antrian Kamu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _queueDisplay(order),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: DamosDominanceColors.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Tunjukkan nomor ini ke Kasir dan bayar dalam waktu '),
                TextSpan(
                  text: _countdownLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _CashStyle.infoBannerBg,
        borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
        border: Border.all(color: DamosDominanceColors.primary.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'QR pengambilan akan diberikan setelah pembayaran dikonfirmasi oleh kasir',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _CashStyle.infoBannerFg,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
        border: Border.all(color: _CashStyle.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          _lineDivider(),
          ...List.generate(order.orderItems.length, (index) {
            final item = order.orderItems[index];
            final qtyLabel = item.variantName != null && item.variantName!.isNotEmpty
                ? '${item.variantName} x${item.quantity}'
                : 'x${item.quantity}';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DamosDominanceColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              qtyLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DamosDominanceColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DamosDominanceColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < order.orderItems.length - 1) _lineDivider(),
              ],
            );
          }),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.total),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton({required bool expired}) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: expired
          ? ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DamosDominanceColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            )
          : OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DamosDominanceColors.primary,
                side: const BorderSide(color: DamosDominanceColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildSimulatePaymentButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _simulatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: DamosDominanceColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simulasi Pembayaran Berhasil',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildSimulateTimeoutButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _expired || _isVerifying ? null : _handleTimeout,
        style: OutlinedButton.styleFrom(
          foregroundColor: DamosDominanceColors.error,
          side: const BorderSide(color: DamosDominanceColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_CashStyle.cardRadius),
          ),
        ),
        child: const Text(
          'Simulasi Waktu Habis',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSimBottomBar() {
    if (_expired) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _CashStyle.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSimulatePaymentButton(),
            if (_showDevControls) ...[
              const SizedBox(height: 8),
              _buildSimulateTimeoutButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredContent(OrderModel order) {
    return Column(
      children: [
        const DamosPageHeader(
          title: 'Bayar di Kasir',
          showBackButton: true,
          backgroundColor: DamosDominanceColors.primary,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildExpiredBannerCard(),
                  const SizedBox(height: 16),
                  _buildOrderSummary(order),
                  const SizedBox(height: 16),
                  _buildHomeButton(expired: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveContent(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DamosPageHeader(
                  title: 'Bayar di Kasir',
                  showBackButton: true,
                  backgroundColor: DamosDominanceColors.primary,
                ),
                _buildWaitingBanner(),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, _showDevControls ? 8 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQueueCard(order),
                      const SizedBox(height: 16),
                      _buildOrderSummary(order),
                      const SizedBox(height: 12),
                      _buildInfoBanner(),
                      const SizedBox(height: 16),
                      _buildHomeButton(expired: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showDevControls) _buildSimBottomBar(),
      ],
    );
  }

  Widget _buildContent(OrderModel order) {
    if (_expired) return _buildExpiredContent(order);
    return _buildActiveContent(order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded) {
            if (_order == null || state.order.id == widget.orderId) {
              setState(() => _order = state.order);
            }

            if (!_expired &&
                !_isVerifying &&
                state.order.id == widget.orderId &&
                state.order.paymentStatus == PaymentStatus.paid) {
              _onPaymentSuccess(state.order.id);
              return;
            }
          }

          if (state is OrderDetailLoaded && _isVerifying) {
            if (state.order.paymentStatus == PaymentStatus.paid) {
              _onPaymentSuccess(state.order.id);
              return;
            }
            setState(() => _isVerifying = false);
            _startCountdown();
            _startPolling();
          }

          if (state is OrderError && (_isVerifying || _isCancelling)) {
            if (_isVerifying) {
              setState(() => _isVerifying = false);
              _startCountdown();
              _startPolling();
            }
            if (!_expired) {
              PopUpAlert.show(
                context: context,
                title: 'Pembayaran Gagal',
                description: state.message,
                isError: true,
              );
            }
          }
        },
        builder: (context, state) {
          final order = _order ?? (state is OrderDetailLoaded ? state.order : null);

          if (order == null || order.id != widget.orderId) {
            return const Center(
              child: CircularProgressIndicator(color: DamosDominanceColors.primary),
            );
          }

          return _buildContent(order);
        },
      ),
    );
  }
}
