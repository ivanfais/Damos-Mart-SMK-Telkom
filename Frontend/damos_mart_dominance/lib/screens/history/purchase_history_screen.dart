import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/complaints/complaint_help_card.dart';

enum _OrderCategory {
  all,
  unpaid,
  processing,
  ready,
  completed,
  cancelled,
}

class _HistoryStyle {
  static const double cardRadius = 8;
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color orangeText = Color(0xFFE65100);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color unpaidRed = Color(0xFFD40000);
  static Color get unpaidRedBg => unpaidRed.withValues(alpha: 0.3);
  static const double tabIndicatorWidth = 64;
  static const double tabIndicatorHeight = 3;
}

class _WideTabIndicator extends Decoration {
  const _WideTabIndicator({required this.color});

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _WideTabIndicatorPainter(this);
  }
}

class _WideTabIndicatorPainter extends BoxPainter {
  _WideTabIndicatorPainter(this.decoration);

  final _WideTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = offset & size;
    final indicatorLeft =
        rect.center.dx - (_HistoryStyle.tabIndicatorWidth / 2);
    final indicatorTop = rect.bottom - _HistoryStyle.tabIndicatorHeight;

    final paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          indicatorLeft,
          indicatorTop,
          _HistoryStyle.tabIndicatorWidth,
          _HistoryStyle.tabIndicatorHeight,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }
}

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    ('Semua', _OrderCategory.all),
    ('Belum Bayar', _OrderCategory.unpaid),
    ('Diproses', _OrderCategory.processing),
    ('Siap Ambil', _OrderCategory.ready),
    ('Selesai', _OrderCategory.completed),
    ('Dibatalkan', _OrderCategory.cancelled),
  ];

  late TabController _tabController;
  bool _historyLoadScheduled = false;
  late final VoidCallback _routeListener;

  void _createTabController({int initialIndex = 0}) {
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, _tabs.length - 1),
    );
  }

  int? _tabIndexFromQuery(String? tab) {
    switch (tab) {
      case 'all':
        return 0;
      case 'unpaid':
        return 1;
      case 'processing':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      case 'cancelled':
        return 5;
      default:
        return null;
    }
  }

  void _applyTabFromRoute() {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    final index = _tabIndexFromQuery(tab);
    if (index == null || _tabController.index == index) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController.index == index) return;
      _tabController.animateTo(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _createTabController();
    _routeListener = () {
      if (!mounted) return;
      _applyTabFromRoute();
    };
    AppRouter.router.routerDelegate.addListener(_routeListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyTabFromRoute();
  }

  @override
  void activate() {
    super.activate();
    context.read<OrderCubit>().loadMyOrders();
    _applyTabFromRoute();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_tabController.length != _tabs.length) {
      _tabController.dispose();
      _createTabController();
    }
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_routeListener);
    _tabController.dispose();
    super.dispose();
  }

  void _openOrderDetail(OrderModel order) {
    context.push('/orders/${order.id}');
  }

  void _openComplaintFlow(OrderModel order) {
    context.push('/orders/${order.id}/complaints/select');
  }

  void _ensureHistoryLoaded() {
    if (_historyLoadScheduled) return;
    _historyLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _historyLoadScheduled = false;
      context.read<OrderCubit>().loadMyOrders();
    });
  }

  bool _needsLogin(OrderHistoryError error) {
    if (error.statusCode == 401) return true;
    final message = error.message.toLowerCase();
    return message.contains('token') || message.contains('unauthorized');
  }

  List<OrderModel>? _resolveOrders(OrderState state, OrderCubit cubit) {
    if (state is OrderHistoryLoaded) return state.orders;
    return cubit.cachedHistoryOrders;
  }

  bool _matchesCategory(OrderModel order, _OrderCategory category) {
    switch (category) {
      case _OrderCategory.all:
        return true;
      case _OrderCategory.unpaid:
        return order.status == OrderStatus.pending &&
            order.paymentStatus == PaymentStatus.unpaid;
      case _OrderCategory.processing:
        return order.status == OrderStatus.paid ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.inProduction;
      case _OrderCategory.ready:
        return order.status == OrderStatus.ready;
      case _OrderCategory.completed:
        return order.status == OrderStatus.completed;
      case _OrderCategory.cancelled:
        return order.status == OrderStatus.cancelled;
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, _OrderCategory category) {
    return orders
        .where((o) => _matchesCategory(o, category))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ({String label, Color bg, Color text}) _statusBadge(OrderModel order) {
    if (order.status == OrderStatus.cancelled) {
      return (
        label: 'Dibatalkan',
        bg: _HistoryStyle.redLight,
        text: DamosDominanceColors.error,
      );
    }
    if (order.status == OrderStatus.completed) {
      return (
        label: 'Selesai',
        bg: _HistoryStyle.greenLight,
        text: DamosDominanceColors.primary,
      );
    }
    if (order.status == OrderStatus.ready) {
      return (
        label: 'Siap Ambil',
        bg: _HistoryStyle.greenLight,
        text: DamosDominanceColors.primary,
      );
    }
    if (order.status == OrderStatus.paid ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.inProduction) {
      return (
        label: 'Diproses',
        bg: _HistoryStyle.orangeLight,
        text: _HistoryStyle.orangeText,
      );
    }
    return (
      label: 'Belum Bayar',
      bg: _HistoryStyle.unpaidRedBg,
      text: _HistoryStyle.unpaidRed,
    );
  }

  bool _isUnpaid(OrderModel order) {
    return order.status == OrderStatus.pending &&
        order.paymentStatus == PaymentStatus.unpaid;
  }

  void _payNow(OrderModel order) {
    if (order.paymentMethod == PaymentMethod.qris) {
      context.push('/checkout/qris/${order.id}', extra: order);
      return;
    }
    context.push('/checkout/cash/${order.id}', extra: order);
  }

  Widget _buildStatusBadge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPayNowButton(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: _HistoryStyle.unpaidRedBg,
          borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
          child: InkWell(
            onTap: () => _payNow(order),
            borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Bayar Sekarang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _HistoryStyle.unpaidRed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: DamosDominanceColors.fieldFill,
        borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(imageUrl),
              fit: BoxFit.cover,
              width: 52,
              height: 52,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.image_outlined,
                color: DamosDominanceColors.textSecondary,
                size: 22,
              ),
            )
          : const Icon(
              Icons.image_outlined,
              color: DamosDominanceColors.textSecondary,
              size: 22,
            ),
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, isLast ? 12 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProductThumbnail(item.imageUrl),
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
                    color: DamosDominanceColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DamosDominanceColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insetDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: DamosDominanceColors.fieldBorder,
      ),
    );
  }

  Widget _buildHistoryCard(OrderModel order) {
    final badge = _statusBadge(order);
    final items = order.orderItems;
    final isCompleted = order.status == OrderStatus.completed;
    final isUnpaid = _isUnpaid(order);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openOrderDetail(order),
        borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
            border: Border.all(
              color: DamosDominanceColors.fieldBorder.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: DamosDominanceColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatOrderHistoryDate(order.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: DamosDominanceColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(badge.label, badge.bg, badge.text),
                  ],
                ),
              ),
              _insetDivider(),
              ...List.generate(items.length, (index) {
                return _buildOrderItemRow(
                  items[index],
                  isLast: index == items.length - 1,
                );
              }),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 10, isUnpaid ? 8 : (isCompleted ? 8 : 14)),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: DamosDominanceColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(order.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: DamosDominanceColors.textHint,
                    ),
                  ],
                ),
              ),
              if (isUnpaid)
                _buildPayNowButton(order)
              else if (isCompleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ComplaintHistoryBanner(
                    onComplaintPressed: () => _openComplaintFlow(order),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyTitle(_OrderCategory category) {
    switch (category) {
      case _OrderCategory.all:
        return 'Belum ada pesanan';
      case _OrderCategory.unpaid:
        return 'Belum ada pesanan belum bayar';
      case _OrderCategory.processing:
        return 'Belum ada pesanan diproses';
      case _OrderCategory.ready:
        return 'Belum ada pesanan siap ambil';
      case _OrderCategory.completed:
        return 'Belum ada pesanan selesai';
      case _OrderCategory.cancelled:
        return 'Belum ada pesanan dibatalkan';
    }
  }

  Widget _buildOrdersList(List<OrderModel> list, _OrderCategory category) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            emoji: '📋',
            title: _emptyTitle(category),
            subtitle: 'Pesanan yang kamu buat akan muncul di sini.',
            actionButtonText: 'Mulai Belanja',
            onActionButtonPressed: () => context.go('/catalog'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: DamosDominanceColors.primary,
      onRefresh: () async => context.read<OrderCubit>().loadMyOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildHistoryCard(list[index]),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_HistoryStyle.cardRadius),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingShimmer(width: 90, height: 14, borderRadius: 4),
                LoadingShimmer(width: 72, height: 22, borderRadius: 20),
              ],
            ),
            SizedBox(height: 6),
            LoadingShimmer(width: 70, height: 12, borderRadius: 4),
            SizedBox(height: 14),
            Row(
              children: [
                LoadingShimmer(width: 48, height: 48, borderRadius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 4),
                      LoadingShimmer(width: 24, height: 12, borderRadius: 4),
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
      backgroundColor: DamosDominanceColors.screenBackground,
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Riwayat Pesanan',
            showBackButton: false,
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: DamosDominanceColors.primary,
              unselectedLabelColor: DamosDominanceColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const _WideTabIndicator(
                color: DamosDominanceColors.primary,
              ),
              dividerColor: DamosDominanceColors.fieldBorder,
              dividerHeight: 1,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
            ),
          ),
          Expanded(
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                final cubit = context.read<OrderCubit>();

                if (state is OrderHistoryLoading) {
                  return _buildShimmerLoading();
                }

                if (state is OrderHistoryError) {
                  final needsLogin = _needsLogin(state);
                  return ErrorState(
                    message: needsLogin
                        ? 'Sesi kamu sudah habis. Silakan login kembali.'
                        : state.message,
                    actionLabel: needsLogin ? 'Login Kembali' : null,
                    onRetry: () {
                      if (needsLogin) {
                        context.go('/login');
                        return;
                      }
                      context.read<OrderCubit>().loadMyOrders();
                    },
                  );
                }

                final orders = _resolveOrders(state, cubit);
                if (orders != null) {
                  return TabBarView(
                    controller: _tabController,
                    children: _tabs
                        .map(
                          (t) => _buildOrdersList(
                            _filterOrders(orders, t.$2),
                            t.$2,
                          ),
                        )
                        .toList(),
                  );
                }

                _ensureHistoryLoaded();
                return _buildShimmerLoading();
              },
            ),
          ),
        ],
      ),
    );
  }
}
