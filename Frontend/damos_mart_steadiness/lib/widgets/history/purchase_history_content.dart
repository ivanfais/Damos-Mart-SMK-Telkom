import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/order_display_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class _Ui {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color emptyCircleBg = Color(0xFFE8F5E9);
  static const Color disabledBtnBg = Color(0xFFE5E7EB);
  static const Color disabledBtnText = Color(0xFF9CA3AF);
  static const Color bg = Color(0xFFF5F5F5);

  static const TextStyle title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    fontFamily: 'Arial',
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 12,
    color: textSecondary,
    fontFamily: 'Arial',
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    color: hint,
    fontFamily: 'Arial',
  );

  static const TextStyle price = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    fontFamily: 'Arial',
  );

  /// Tema global app memakai minimumSize lebar infinite — pecah layout di Row/ListView.
  static ButtonStyle compactElevatedStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? disabledBackgroundColor,
    Color? disabledForegroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    double elevation = 0,
    OutlinedBorder? shape,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize ?? Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// Daftar riwayat transaksi — harus ditempatkan di dalam [Expanded].
class PurchaseHistoryContent extends StatefulWidget {
  const PurchaseHistoryContent({super.key});

  @override
  State<PurchaseHistoryContent> createState() => _PurchaseHistoryContentState();
}

class _PurchaseHistoryContentState extends State<PurchaseHistoryContent> {
  final OrderRepository _repository = OrderRepository();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _repository.getMyOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
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

  Widget _statusBadge(String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, fontFamily: 'Arial'),
      ),
    );
  }

  Widget _productThumb(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF3F4F6),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(url),
                fit: BoxFit.cover,
                width: 52,
                height: 52,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.shopping_bag_outlined, color: _Ui.hint, size: 22),
              )
            : const Icon(Icons.shopping_bag_outlined, color: _Ui.hint, size: 22),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final badge = OrderDisplayUtils.statusBadge(order);
    final item = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final canBuy = OrderDisplayUtils.canBuyAgain(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ui.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _productThumb(item?.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OrderDisplayUtils.productName(order),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _Ui.title,
                    ),
                    const SizedBox(height: 4),
                    Text(OrderDisplayUtils.dateBarangLine(order), style: _Ui.subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(badge.label, badge.bg, badge.text),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: _Ui.border),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Belanja', style: _Ui.label),
                    const SizedBox(height: 2),
                    Text(CurrencyFormatter.format(order.total), style: _Ui.price),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: canBuy ? () => _buyAgain(order) : null,
                  style: _Ui.compactElevatedStyle(
                    backgroundColor: canBuy ? _Ui.primary : _Ui.disabledBtnBg,
                    foregroundColor: canBuy ? Colors.white : _Ui.disabledBtnText,
                    disabledBackgroundColor: _Ui.disabledBtnBg,
                    disabledForegroundColor: _Ui.disabledBtnText,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text(
                    'Beli Lagi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Arial'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(color: _Ui.emptyCircleBg, shape: BoxShape.circle),
          child: const Icon(Icons.shopping_cart_outlined, size: 40, color: Color(0xFF4DB6AC)),
        ),
        const SizedBox(height: 20),
        const Text(
          'Belum ada riwayat transaksi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _Ui.textPrimary,
            fontFamily: 'Arial',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Riwayat pembelian Anda akan muncul di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _Ui.textSecondary, fontFamily: 'Arial'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/catalog'),
            style: _Ui.compactElevatedStyle(
              backgroundColor: _Ui.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Arial'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Color(0xFFD42427)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _Ui.textSecondary, fontFamily: 'Arial'),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchOrders,
          style: _Ui.compactElevatedStyle(
            backgroundColor: _Ui.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Arial')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: _Ui.compactElevatedStyle(),
        ),
      ),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: _Ui.bg,
        child: Center(child: CircularProgressIndicator(color: _Ui.primary)),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: _Ui.bg,
        child: RefreshIndicator(
          color: _Ui.primary,
          onRefresh: _fetchOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.45,
                child: _errorState(),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return ColoredBox(
        color: _Ui.bg,
        child: RefreshIndicator(
          color: _Ui.primary,
          onRefresh: _fetchOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: _emptyState(),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: _Ui.bg,
      child: RefreshIndicator(
        color: _Ui.primary,
        onRefresh: _fetchOrders,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _orders.length,
          itemBuilder: (context, index) => _orderCard(_orders[index]),
        ),
      ),
    );
  }
}
