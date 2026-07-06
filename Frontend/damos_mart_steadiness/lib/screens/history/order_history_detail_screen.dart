import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/order_display_utils.dart';
import '../../core/utils/receipt_display_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF9FAFB);
  static const Color disabledBtnBg = Color(0xFFE5E7EB);
  static const Color disabledBtnText = Color(0xFF9CA3AF);
}

class OrderHistoryDetailScreen extends StatefulWidget {
  const OrderHistoryDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderHistoryDetailScreen> createState() => _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  final OrderRepository _orderRepository = OrderRepository();

  OrderModel? _order;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderRepository.getOrderDetails(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _buyAgain(OrderModel order) {
    if (!OrderDisplayUtils.canBuyAgain(order)) return;
    final item = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    if (item != null && item.productId.isNotEmpty) {
      context.push('/catalog/${item.productId}');
      return;
    }
    context.go('/catalog');
  }

  double _adminFee(OrderModel order) => ReceiptDisplayUtils.adminFee(order);

  Widget _statusBadge(OrderModel order) {
    final badge = OrderDisplayUtils.detailStatusBadge(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badge.text,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _Ds.textSecondary,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Ds.textPrimary,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productThumb(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF3F4F6),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(url),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 22),
              )
            : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 22),
      ),
    );
  }

  Widget _buildSummaryCard(OrderModel order) {
    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productThumb(firstItem?.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OrderDisplayUtils.productName(order),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Ds.textPrimary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  OrderDisplayUtils.dateBarangLine(order),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Ds.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Ds.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(order),
        ],
      ),
    );
  }

  Widget _buildInfoCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoRow('Tanggal Pesanan', ReceiptDisplayUtils.formatDateTime(order.createdAt)),
          _infoRow('Metode Pembayaran', ReceiptDisplayUtils.paymentMethodLabel(order)),
          _infoRow('Status Pembayaran', ReceiptDisplayUtils.paymentStatusLabel(order)),
          _infoRow('Jenis Pesanan', ReceiptDisplayUtils.orderTypeLabel(order)),
          if (order.queueNumber != null && order.queueNumber!.isNotEmpty)
            _infoRow('Nomor Antrean', ReceiptDisplayUtils.queueLabel(order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productThumb(item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Ds.primary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                if (item.variantName != null && item.variantName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Ds.textSecondary,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x • ${CurrencyFormatter.format(item.productPrice)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Ds.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
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
              color: _Ds.textPrimary,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Pesanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Ds.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < order.orderItems.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: _Ds.border),
                _buildOrderItem(order.orderItems[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            color: isBold ? _Ds.primary : _Ds.textSecondary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? _Ds.primary : _Ds.textPrimary,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    final adminFee = _adminFee(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', CurrencyFormatter.format(order.subtotal)),
          const SizedBox(height: 8),
          _priceRow('Biaya Admin', CurrencyFormatter.format(adminFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _Ds.border),
          ),
          _priceRow('Total Belanja', CurrencyFormatter.format(order.total), isBold: true),
        ],
      ),
    );
  }

  Widget _buildActions(OrderModel order) {
    final canBuy = OrderDisplayUtils.canBuyAgain(order);
    final canShowReceipt = order.paymentStatus == PaymentStatus.paid ||
        order.status == OrderStatus.completed;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: canBuy ? () => _buyAgain(order) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canBuy ? _Ds.primary : _Ds.disabledBtnBg,
              foregroundColor: canBuy ? Colors.white : _Ds.disabledBtnText,
              disabledBackgroundColor: _Ds.disabledBtnBg,
              disabledForegroundColor: _Ds.disabledBtnText,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Beli Lagi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ),
        if (canShowReceipt) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/checkout/receipt/${order.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _Ds.primary,
                side: const BorderSide(color: _Ds.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              label: const Text(
                'Lihat Struk Digital',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: AppTextStyles.fontFamily),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(OrderModel order) {
    return RefreshIndicator(
      color: _Ds.primary,
      onRefresh: _loadOrder,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(order),
            const SizedBox(height: 14),
            _buildInfoCard(order),
            const SizedBox(height: 20),
            _buildOrderItems(order),
            const SizedBox(height: 16),
            _buildPriceSummary(order),
            const SizedBox(height: 24),
            _buildActions(order),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: Column(
        children: [
          const SteadinessTitleHeader(title: 'Detail Riwayat'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ProductGridShimmer(itemCount: 2),
      );
    }

    if (_errorMessage != null || _order == null) {
      return ErrorState(
        message: _errorMessage ?? 'Gagal memuat detail riwayat.',
        onRetry: () {
          setState(() => _isLoading = true);
          _loadOrder();
        },
      );
    }

    return _buildContent(_order!);
  }
}
