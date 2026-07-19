import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color red = Color(0xFFD42427);
  static const Color yellowBg = Color(0xFFF5C518);
  static const Color completedBadgeBg = Color(0xFFF2F2F2);
}

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<OrderCubit>().loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Sama persis dengan heuristik _isSeragamQueue di queue_list_screen.dart,
  // supaya pesanan yang dianggap "seragam" konsisten di seluruh app.
  // Pesanan seragam punya alur lacak pesanan sendiri di modul Seragam,
  // jadi tidak ditampilkan di Riwayat Transaksi produk koperasi biasa.
  static const _seragamKeywords = ['seragam', 'baju', 'kemeja', 'batik', 'pramuka', 'olahraga', 'pakaian'];

  bool _isSeragamOrder(OrderModel order) {
    final notes = order.notes?.toLowerCase() ?? '';
    if (notes.contains('seragam') || notes.contains('transfer bank')) return true;
    return order.orderItems.any((i) {
      final name = i.productName.toLowerCase();
      return _seragamKeywords.any((kw) => name.contains(kw));
    });
  }

  void _openOrderDetail(OrderModel order) {
    context.push('/profile/history/${order.id}');
  }

  ({String label, Color bg, Color text}) _statusBadge(OrderModel order) {
    if (order.status == OrderStatus.cancelled) {
      return (label: 'Dibatalkan', bg: const Color(0xFFFEE2E2), text: _Ds.red);
    }
    if (order.status == OrderStatus.completed) {
      return (label: 'Pesanan Selesai', bg: _Ds.completedBadgeBg, text: _Ds.red);
    }
    if (order.status == OrderStatus.ready) {
      return (label: 'Siap Diambil', bg: _Ds.greenLight, text: _Ds.primary);
    }
    if (order.status == OrderStatus.preparing || order.status == OrderStatus.inProduction) {
      return (label: 'Diproses', bg: _Ds.yellowBg, text: _Ds.textPrimary);
    }
    return (label: 'Menunggu', bg: _Ds.yellowBg, text: _Ds.textPrimary);
  }

  Widget _buildStatusBadge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _Ds.bgGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(imageUrl),
              fit: BoxFit.cover,
              width: 64,
              height: 64,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _Ds.primary),
                ),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
            )
          : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
    );
  }

  Widget _buildHistoryCard(OrderModel order) {
    final badge = _statusBadge(order);
    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final productName = firstItem?.productName ?? 'Produk';
    final qtyLabel = '${firstItem?.quantity ?? 1}X';
    final priceLabel = CurrencyFormatter.format(firstItem?.subtotal ?? order.total);
    final dateLabel = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(order.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
              ),
              _buildStatusBadge(badge.label, badge.bg, badge.text),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProductThumbnail(firstItem?.imageUrl),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qtyLabel,
                    style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _Ds.borderLight),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _openOrderDetail(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 140, height: 1, color: _Ds.borderLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _Ds.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> list, {required bool isCompletedTab}) {
    if (list.isEmpty) {
      return _buildEmptyState(
        isCompletedTab ? 'Belum Ada Pesanan Selesai' : 'Belum Ada Pesanan Aktif',
      );
    }

    return RefreshIndicator(
      color: _Ds.primary,
      onRefresh: () async => context.read<OrderCubit>().loadMyOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildHistoryCard(list[index]),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingShimmer(width: 140, height: 16, borderRadius: 4),
                LoadingShimmer(width: 90, height: 22, borderRadius: 20),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                LoadingShimmer(width: 64, height: 64, borderRadius: 8),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer(width: 40, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    LoadingShimmer(width: 90, height: 16, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgLight,
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Riwayat Transaksi',
            showBackButton: true,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _Ds.primary,
              unselectedLabelColor: _Ds.textSecondary,
              indicatorColor: _Ds.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Aktif'),
                Tab(text: 'Selesai'),
              ],
            ),
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
                    onRetry: () => context.read<OrderCubit>().loadMyOrders(),
                  );
                }

                if (state is OrderHistoryLoaded) {
                  final orders = state.orders.where((o) => !_isSeragamOrder(o)).toList();

                  final activeOrders = orders
                      .where(
                        (o) =>
                            o.status == OrderStatus.pending ||
                            o.status == OrderStatus.paid ||
                            o.status == OrderStatus.preparing ||
                            o.status == OrderStatus.inProduction ||
                            o.status == OrderStatus.ready,
                      )
                      .toList();

                  final pastOrders = orders
                      .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(activeOrders, isCompletedTab: false),
                      _buildOrdersList(pastOrders, isCompletedTab: true),
                    ],
                  );
                }

                return const Center(child: Text('Memuat riwayat pembelian...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
