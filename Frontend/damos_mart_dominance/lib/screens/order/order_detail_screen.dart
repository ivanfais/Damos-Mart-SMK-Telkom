import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/cart_navigation.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/preorder_date_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../core/notifications/complaint_realtime_service.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/order/damos_pickup_qr_card.dart';
import '../../widgets/complaints/complaint_help_card.dart';

class _Style {
  static const double cardRadius = 8;
  static const Color cardBorder = DamosDominanceColors.fieldBorder;
  static const Color orangeBg = Color(0xFFFFF3E0);
  static const Color orangeFg = Color(0xFFE65100);
  static const Color redBg = Color(0xFFFFEBEE);
  static const Color redFg = Color(0xFFD42427);
  static const Color greenBg = Color(0xFFE8F5E9);
}

enum _DetailCategory {
  unpaid,
  processing,
  ready,
  completed,
  cancelled,
}

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _preorderEstimate;
  final _complaintRepository = ComplaintRepository();
  List<ComplaintModel> _orderComplaints = [];
  bool _complaintsLoaded = false;
  StreamSubscription<Map<String, dynamic>>? _complaintRealtimeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderCubit>().loadOrderDetail(widget.orderId);
        _loadComplaints();
      }
    });
    _complaintRealtimeSub =
        ComplaintRealtimeService.instance.updates.listen((data) {
      final orderId = data['orderId']?.toString();
      if (orderId != null && orderId != widget.orderId) return;
      _loadComplaints();
    });
  }

  @override
  void dispose() {
    _complaintRealtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    try {
      final complaints =
          await _complaintRepository.getComplaintsForOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _orderComplaints = complaints;
        _complaintsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _complaintsLoaded = true);
    }
  }

  void _openComplaintFlow() {
    context.push('/orders/${widget.orderId}/complaints/select');
  }

  void _openComplaintDetail(ComplaintModel complaint) {
    context.push('/complaints/${complaint.id}');
  }

  ComplaintModel? get _latestComplaint {
    if (_orderComplaints.isEmpty) return null;
    return _orderComplaints.first;
  }

  @override
  void activate() {
    super.activate();
    _loadComplaints();
  }

  _DetailCategory _category(OrderModel order) {
    if (order.status == OrderStatus.cancelled) return _DetailCategory.cancelled;
    if (order.status == OrderStatus.pending &&
        order.paymentStatus == PaymentStatus.unpaid) {
      return _DetailCategory.unpaid;
    }
    if (order.status == OrderStatus.completed) return _DetailCategory.completed;
    if (order.status == OrderStatus.ready) return _DetailCategory.ready;
    return _DetailCategory.processing;
  }

  ({Color bg, Color fg, String label}) _statusTheme(_DetailCategory category) {
    switch (category) {
      case _DetailCategory.unpaid:
      case _DetailCategory.cancelled:
        return (bg: _Style.redBg, fg: _Style.redFg, label: category == _DetailCategory.unpaid ? 'Belum Bayar' : 'Dibatalkan');
      case _DetailCategory.completed:
      case _DetailCategory.ready:
        return (
          bg: _Style.greenBg,
          fg: DamosDominanceColors.primary,
          label: category == _DetailCategory.completed ? 'Selesai' : 'Siap Ambil',
        );
      case _DetailCategory.processing:
        return (bg: _Style.orangeBg, fg: _Style.orangeFg, label: 'Diproses');
    }
  }

  bool _showQueueCard(_DetailCategory category) {
    return category == _DetailCategory.processing ||
        category == _DetailCategory.ready ||
        category == _DetailCategory.completed;
  }

  bool _showPreorderEstimate(OrderModel order, _DetailCategory category) {
    return order.isPreorder && category == _DetailCategory.processing;
  }

  Future<void> _loadPreorderEstimate(OrderModel order) async {
    if (!order.isPreorder || _preorderEstimate != null) return;

    final baseDate = order.paidAt ?? order.createdAt;
    var productionDays = 14;

    try {
      final repo = ProductRepository();
      for (final item in order.orderItems) {
        final product = await repo.getProductDetail(item.productId);
        if (product.isPreorder) {
          final days = PreorderDateUtils.parseProductionDays(product.preorderEstimation);
          if (days > productionDays) productionDays = days;
        }
      }
    } catch (_) {
      // Fallback ke estimasi default.
    }

    if (!mounted) return;
    setState(() {
      _preorderEstimate = PreorderDateUtils.completionRangeFromBase(baseDate, productionDays);
    });
  }

  void _payNow(OrderModel order) {
    if (order.paymentMethod == PaymentMethod.qris) {
      context.push('/checkout/qris/${order.id}', extra: order);
      return;
    }
    context.push('/checkout/cash/${order.id}', extra: order);
  }

  Future<void> _buyAgain(OrderModel order) async {
    if (order.orderItems.isEmpty) {
      context.go('/catalog');
      return;
    }

    final cartCubit = context.read<CartCubit>();
    for (final item in order.orderItems) {
      await cartCubit.addToCart(
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
      );
    }

    if (!mounted) return;
    CartNavigation.open(context);
  }

  Widget _lineDivider() {
    return const Divider(height: 1, thickness: 1, color: _Style.cardBorder);
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Style.cardRadius),
        border: Border.all(color: _Style.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
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

  String _queueDisplay(OrderModel order) {
    final number = order.queueNumber;
    if (number == null || number.isEmpty) return '#---';
    if (number.startsWith('#')) return number;

    final digits = RegExp(r'(\d+)').firstMatch(number)?.group(1);
    if (digits != null) {
      return '#${digits.padLeft(3, '0')}';
    }
    return '#$number';
  }

  Color _statusBorderColor(_DetailCategory category, Color fg) {
    switch (category) {
      case _DetailCategory.unpaid:
      case _DetailCategory.cancelled:
        return fg.withValues(alpha: 0.35);
      default:
        return _Style.cardBorder;
    }
  }

  Widget _buildStatusCard(
    OrderModel order,
    _DetailCategory category,
    ({Color bg, Color fg, String label}) theme,
  ) {
    final showEstimate = _showPreorderEstimate(order, category);
    if (showEstimate && _preorderEstimate == null) {
      _loadPreorderEstimate(order);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(_Style.cardRadius),
        border: Border.all(color: _statusBorderColor(category, theme.fg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            theme.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${order.orderNumber} | ${DateFormatter.formatOrderDetailHeader(order.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.fg.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          if (showEstimate) ...[
            const SizedBox(height: 8),
            Text(
              'Estimasi selesai ${_preorderEstimate ?? PreorderDateUtils.completionRangeFromBase(order.paidAt ?? order.createdAt, 14)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: DamosDominanceColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _pickupQrData(OrderModel order) {
    return order.queueId ?? order.id;
  }

  Widget _buildPickupQrCard(OrderModel order) {
    return DamosPickupQrCard(qrData: _pickupQrData(order));
  }

  Widget _buildQueueCard(OrderModel order) {
    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Nomor Antrian',
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(OrderModel order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Produk Dipesan',
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
                              item.displaySubtitle,
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
        ],
      ),
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    bool valueGreen = false,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: DamosDominanceColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
            color: valueGreen
                ? DamosDominanceColors.primary
                : DamosDominanceColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Informasi Pembayaran',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _paymentRow('Metode Pembayaran', _paymentMethodLabel(order.paymentMethod)),
                const SizedBox(height: 8),
                _paymentRow('Subtotal', CurrencyFormatter.format(order.subtotal)),
                const SizedBox(height: 8),
                _paymentRow('Biaya Layanan', 'Gratis', valueGreen: true),
              ],
            ),
          ),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _paymentRow(
              'Total',
              CurrencyFormatter.format(order.total),
              valueGreen: true,
              valueBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomAction(_DetailCategory category, OrderModel order) {
    switch (category) {
      case _DetailCategory.unpaid:
        return SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _payNow(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: DamosDominanceColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Style.cardRadius),
              ),
            ),
            child: const Text(
              'Bayar Sekarang',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _DetailCategory.completed:
        return SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _buyAgain(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: DamosDominanceColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Style.cardRadius),
              ),
            ),
            child: const Text(
              'Beli Lagi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildContent(OrderModel order) {
    final category = _category(order);
    final theme = _statusTheme(category);
    final bottomAction = _buildBottomAction(category, order);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DamosPageHeader(
                  title: 'Detail Pesanan',
                  showBackButton: true,
                  backgroundColor: DamosDominanceColors.primary,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: [
                      _buildStatusCard(order, category, theme),
                      if (_showQueueCard(category)) ...[
                        const SizedBox(height: 12),
                        _buildQueueCard(order),
                      ],
                      if (category == _DetailCategory.ready) ...[
                        const SizedBox(height: 12),
                        _buildPickupQrCard(order),
                      ],
                      const SizedBox(height: 12),
                      _buildProductsCard(order),
                      if (category == _DetailCategory.completed) ...[
                        const SizedBox(height: 12),
                        if (_complaintsLoaded && _latestComplaint != null) ...[
                          ComplaintStatusSummaryCard(
                            complaint: _latestComplaint!,
                            onTap: () => _openComplaintDetail(_latestComplaint!),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_complaintsLoaded)
                          ComplaintHelpCard(
                            onComplaintPressed: _openComplaintFlow,
                          ),
                      ],
                      const SizedBox(height: 12),
                      _buildPaymentCard(order),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bottomAction != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _Style.cardBorder)),
            ),
            child: SafeArea(top: false, child: bottomAction),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<OrderCubit>().loadOrderDetail(widget.orderId),
            );
          }

          if (state is OrderDetailLoaded && state.order.id == widget.orderId) {
            return _buildContent(state.order);
          }

          return const Center(
            child: CircularProgressIndicator(color: DamosDominanceColors.primary),
          );
        },
      ),
    );
  }
}
