import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/empty_state.dart';
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

  void _openOrderDetail(OrderModel order) {
    if (order.queueId != null) {
      if (order.isPreorder && order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) {
        context.push('/queue/${order.queueId}/tracking');
        return;
      }
      if (order.status == OrderStatus.completed) {
        context.push('/queue/${order.queueId}/complete');
        return;
      }
      context.push('/queue/${order.queueId}');
      return;
    }
    context.push('/checkout/ticket/${order.id}');
  }

  String _cardTitle(OrderModel order, {required bool isCompletedTab}) {
    if (isCompletedTab && order.status == OrderStatus.completed) {
      return 'Order Completed';
    }
    if (order.status == OrderStatus.cancelled) {
      return 'Pesanan Dibatalkan';
    }
    if (order.orderItems.isNotEmpty) {
      return order.orderItems.first.productName;
    }
    return 'Pesanan Aktif';
  }

  ({String label, Color bg, Color text}) _statusBadge(OrderModel order, {required bool isCompletedTab}) {
    if (order.status == OrderStatus.completed) {
      return (label: 'Pesanan Selesai', bg: _Ds.greenLight, text: _Ds.primary);
    }
    if (order.status == OrderStatus.cancelled) {
      return (label: 'Dibatalkan', bg: const Color(0xFFFEE2E2), text: _Ds.red);
    }
    if (order.status == OrderStatus.ready) {
      return (label: 'Siap Diambil', bg: _Ds.greenLight, text: _Ds.primary);
    }
    if (order.status == OrderStatus.inProduction) {
      return (label: 'Dalam Produksi', bg: const Color(0xFFFFF8E1), text: const Color(0xFFF59E0B));
    }
    if (order.status == OrderStatus.preparing) {
      return (label: 'Sedang Disiapkan', bg: _Ds.greenLight, text: _Ds.primary);
    }
    if (order.status == OrderStatus.paid) {
      return (label: 'Menunggu Antrean', bg: _Ds.greenLight, text: _Ds.primary);
    }
    return (label: 'Menunggu Pembayaran', bg: const Color(0xFFFFF8E1), text: const Color(0xFFF59E0B));
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _Ds.bgGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(imageUrl),
              fit: BoxFit.cover,
              width: 56,
              height: 56,
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

  Widget _buildHistoryCard(OrderModel order, {required bool isCompletedTab}) {
    final badge = _statusBadge(order, isCompletedTab: isCompletedTab);
    final totalItems = order.orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final productName = firstItem?.productName ?? 'Produk';
    final itemCaption = firstItem != null
        ? '$totalItems item • ${CurrencyFormatter.format(firstItem.subtotal)}'
        : '$totalItems item • ${CurrencyFormatter.format(order.total)}';
    final dateLine = '${DateFormatter.formatShort(order.createdAt)} • ${order.orderNumber}';

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
                  dateLine,
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ),
              _buildStatusBadge(badge.label, badge.bg, badge.text),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cardTitle(order, isCompletedTab: isCompletedTab),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductThumbnail(firstItem?.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _Ds.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemCaption,
                      style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                  ],
                ),
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
                    const Text(
                      'Total Pesanan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: _Ds.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(order.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> list, {required bool isCompletedTab}) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            emoji: isCompletedTab ? '📜' : '🛒',
            title: isCompletedTab ? 'Belum ada riwayat selesai' : 'Belum ada pesanan aktif',
            subtitle: isCompletedTab
                ? 'Pesanan yang sudah selesai akan muncul di sini.'
                : 'Pesanan yang sedang diproses akan muncul di sini.',
            actionButtonText: 'Mulai Belanja',
            onActionButtonPressed: () => context.go('/catalog'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _Ds.primary,
      onRefresh: () async => context.read<OrderCubit>().loadMyOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildHistoryCard(list[index], isCompletedTab: isCompletedTab);
        },
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
                LoadingShimmer(width: 120, height: 12, borderRadius: 4),
                LoadingShimmer(width: 90, height: 22, borderRadius: 20),
              ],
            ),
            SizedBox(height: 12),
            LoadingShimmer(width: 160, height: 20, borderRadius: 6),
            SizedBox(height: 12),
            Row(
              children: [
                LoadingShimmer(width: 56, height: 56, borderRadius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(width: 120, height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      LoadingShimmer(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
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
              title: 'Riwayat Pembelian',
              showBackButton: true,
            ),
            Material(
              color: _Ds.primary,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                    final orders = state.orders;

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
