import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/env.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';

class _QrisStyle {
  static const double cardRadius = 8;
  static const Color cardBorder = DamosDominanceColors.fieldBorder;
  static const Color waitingBannerBg = Color(0xFFFFF3E0);
  static const Color waitingBannerFg = Color(0xFFE65100);
  static const Color expiredBannerBg = Color(0xFFFFEBEE);
  static const Color expiredBannerFg = Color(0xFFD42427);
  static const Color qrisRed = Color(0xFFE53935);
  static const Color qrisPanelBg = Color(0xFFF3F4F6);

  static const int paymentTimeoutSeconds = 15 * 60;
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
  OrderModel? _order;
  Timer? _countdownTimer;
  int _remainingSeconds = _QrisStyle.paymentTimeoutSeconds;
  bool _expired = false;
  bool _isVerifying = false;
  bool _isCancelling = false;

  bool get _showSimControls => kDebugMode || Env.showPaymentSimulation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _QrisStyle.paymentTimeoutSeconds;
    _expired = false;
    _isVerifying = false;
    _isCancelling = false;
    _order = widget.order;
    if (_order == null) {
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    }
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  Future<void> _handleTimeout() async {
    if (_expired || !mounted) return;

    _countdownTimer?.cancel();
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
    if (value > _QrisStyle.paymentTimeoutSeconds) {
      return _QrisStyle.paymentTimeoutSeconds;
    }
    return value;
  }

  String get _countdownLabel {
    final total = _safeRemainingSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}.${seconds.toString().padLeft(2, '0')}';
  }

  String _qrisPayload(OrderModel order) {
    final total = order.total.isFinite ? order.total : 0;
    return 'DAMOS-MART|${order.orderNumber}|${total.toStringAsFixed(0)}|NMID:ID1023245678901';
  }

  Future<void> _simulatePayment() async {
    if (_isVerifying || _expired || _order == null) return;

    _countdownTimer?.cancel();
    setState(() {
      _isVerifying = true;
      _remainingSeconds = 0;
    });

    await context.read<OrderCubit>().payOrder(
          _order!.id,
          paymentMethod: 'QRIS',
        );
  }

  Future<void> _onPaymentSuccess(String orderId) async {
    _countdownTimer?.cancel();
    context.read<CartCubit>().loadCart();
    await PopUpAlert.showPaymentSuccess(context: context);
    if (!mounted) return;
    context.go('/orders/$orderId');
  }

  void _saveQrCode() {
    PopUpAlert.show(
      context: context,
      title: 'QR Code Disimpan',
      description: 'QR Code pembayaran berhasil disimpan ke perangkat.',
    );
  }

  Widget _lineDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _QrisStyle.cardBorder,
    );
  }

  Widget _buildWaitingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _QrisStyle.waitingBannerBg,
      child: Row(
        children: [
          Icon(Icons.access_time, size: 20, color: _QrisStyle.waitingBannerFg),
          const SizedBox(width: 8),
          Text(
            'Menunggu Pembayaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _QrisStyle.waitingBannerFg,
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
        color: _QrisStyle.expiredBannerBg,
        borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 20, color: _QrisStyle.expiredBannerFg),
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
                    color: _QrisStyle.expiredBannerFg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Waktu Pembayaran habis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _QrisStyle.expiredBannerFg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Batas waktu transaksi',
          style: TextStyle(
            fontSize: 13,
            color: DamosDominanceColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
            border: Border.all(color: _QrisStyle.cardBorder),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: DamosDominanceColors.textPrimary,
              ),
              children: [
                const TextSpan(text: 'Selesaikan dalam '),
                TextSpan(
                  text: _countdownLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrisPanel(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _QrisStyle.qrisPanelBg,
        borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
        border: Border.all(color: _QrisStyle.cardBorder),
      ),
      child: Column(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: 'QRIS',
                  style: TextStyle(color: _QrisStyle.qrisRed),
                ),
                TextSpan(
                  text: ' DAMOS MART Koperasi',
                  style: TextStyle(color: DamosDominanceColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
              border: Border.all(color: _QrisStyle.cardBorder),
            ),
            child: Column(
              children: [
                const Text(
                  'QRIS  ·  GPN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DAMOS MART',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'NMID: ID1023245678901',
                  style: TextStyle(
                    fontSize: 11,
                    color: DamosDominanceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showSimControls && !_isVerifying && !_expired
                      ? _simulatePayment
                      : null,
                  onLongPress:
                      _showSimControls && !_isVerifying && !_expired
                          ? _handleTimeout
                          : null,
                  child: QrImageView(
                    data: _qrisPayload(order),
                    version: QrVersions.auto,
                    size: 200,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: DamosDominanceColors.textPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                ),
                if (_showSimControls) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Mode uji: ketuk QR = bayar berhasil, tahan QR = waktu habis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DamosDominanceColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Cek aplikasi penyelenggara di: www.aspi-qris.id',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: DamosDominanceColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'QR Code ini berlaku untuk satu kali transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: DamosDominanceColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveQrButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saveQrCode,
        icon: const Icon(Icons.download_outlined, size: 18),
        label: const Text(
          'Simpan QR Code',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DamosDominanceColors.primary,
          side: const BorderSide(color: DamosDominanceColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
          ),
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
            borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
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

  Widget _buildOrderSummary(OrderModel order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
        border: Border.all(color: _QrisStyle.cardBorder),
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
            borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
          ),
        ),
        child: const Text(
          'Simulasi Waktu Habis',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDevControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Simulasi Pembayaran (Mode Uji)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DamosDominanceColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSimulatePaymentButton(),
        const SizedBox(height: 8),
        _buildSimulateTimeoutButton(),
      ],
    );
  }

  Widget _buildExpiredAction() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/home'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DamosDominanceColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_QrisStyle.cardRadius),
          ),
        ),
        child: const Text(
          'Kembali ke Beranda',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildExpiredContent(OrderModel order) {
    return Column(
      children: [
        const DamosPageHeader(
          title: 'Pembayaran QRIS',
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
                  _buildExpiredAction(),
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
                  title: 'Pembayaran QRIS',
                  showBackButton: true,
                  backgroundColor: DamosDominanceColors.primary,
                ),
                _buildWaitingBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCountdownSection(),
                      const SizedBox(height: 16),
                      _buildQrisPanel(order),
                      const SizedBox(height: 12),
                      _buildSaveQrButton(),
                      const SizedBox(height: 16),
                      _buildOrderSummary(order),
                      if (_showSimControls) _buildDevControlsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          if (state is OrderDetailLoaded && _order == null) {
            setState(() => _order = state.order);
          }

          if (state is OrderDetailLoaded && _isVerifying) {
            if (state.order.paymentStatus == PaymentStatus.paid) {
              _onPaymentSuccess(state.order.id);
              return;
            }
            setState(() {
              _isVerifying = false;
              _remainingSeconds = _QrisStyle.paymentTimeoutSeconds;
            });
            _startCountdown();
          }

          if (state is OrderError && (_isVerifying || _isCancelling)) {
            if (_isVerifying) {
              setState(() {
                _isVerifying = false;
                _remainingSeconds = _QrisStyle.paymentTimeoutSeconds;
              });
              _startCountdown();
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

          if (order == null) {
            return const DamosOrderDetailShimmer();
          }

          if (_order == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _order = order);
            });
          }

          return _buildContent(order);
        },
      ),
    );
  }
}
