import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color red = Color(0xFFD42427);
}

class OrderHistoryDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderHistoryDetailScreen({super.key, required this.orderId});

  @override
  State<OrderHistoryDetailScreen> createState() => _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  String _paymentMethodLabel(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.cashAtCounter:
        return 'Tunai di Kasir';
      default:
        return '-';
    }
  }

  ({String label, Color bg, Color border, Color text}) _orderStatusInfo(OrderModel order) {
    if (order.status == OrderStatus.cancelled) {
      return (label: 'Dibatalkan', bg: const Color(0xFFFEE2E2), border: _Ds.red, text: _Ds.red);
    }
    if (order.status == OrderStatus.completed) {
      return (label: 'Selesai', bg: _Ds.greenLight, border: _Ds.primary, text: _Ds.primary);
    }
    return (label: 'Aktif', bg: _Ds.greenLight, border: _Ds.primary, text: _Ds.primary);
  }

  Widget _buildProductCard(OrderModel order) {
    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: firstItem?.imageUrl != null && firstItem!.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ApiConfig.imageUrl(firstItem.imageUrl!),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _Ds.primary),
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstItem?.productName ?? 'Produk',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${firstItem?.quantity ?? 1}X',
                  style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(firstItem?.subtotal ?? order.total),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? _Ds.textPrimary : _Ds.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: _Ds.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('ID Pesanan', order.orderNumber),
          _buildSummaryRow('Metode Pembayaran', _paymentMethodLabel(order.paymentMethod)),
          _buildSummaryRow(
            'Waktu Transaksi',
            DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(order.createdAt),
          ),
          const SizedBox(height: 6),
          const Divider(color: _Ds.textPrimary, height: 1, thickness: 0.6),
          const SizedBox(height: 6),
          _buildSummaryRow('Total Tagihan', CurrencyFormatter.format(order.total), emphasize: true),
        ],
      ),
    );
  }

  Widget _buildStatusBox(OrderModel order) {
    final info = _orderStatusInfo(order);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.border),
      ),
      child: Text(
        'Status Pesanan : ${info.label}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: info.text),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 8),
          const Divider(color: _Ds.borderLight, height: 1),
          const SizedBox(height: 16),
          _buildProductCard(order),
          const SizedBox(height: 16),
          _buildSummaryCard(order),
          const SizedBox(height: 16),
          _buildStatusBox(order),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer(width: 140, height: 18, borderRadius: 4),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 84, borderRadius: 12),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 180, borderRadius: 12),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 50, borderRadius: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Riwayat Transaksi',
            showBackButton: true,
          ),
          Expanded(
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return _buildShimmerLoading();
                }
                if (state is OrderError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => context.read<OrderCubit>().loadOrderDetail(widget.orderId),
                  );
                }
                if (state is OrderDetailLoaded) {
                  return SingleChildScrollView(child: _buildContent(state.order));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
