import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/cart_item_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import '../../core/utils/cart_navigation.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItemIds = {};
  final Set<String> _dismissedItemIds = {};

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _toggleSelectAll(bool? selectAll, List<CartItemModel> items) {
    setState(() {
      if (selectAll == true) {
        _selectedItemIds
          ..clear()
          ..addAll(items.where((i) => i.inStock).map((i) => i.id));
      } else {
        _selectedItemIds.clear();
      }
    });
  }

  double _calculateSelectedTotal(List<CartItemModel> items) {
    var total = 0.0;
    for (final item in items) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.subtotal;
      }
    }
    return total;
  }

  int _selectedCount(List<CartItemModel> items) {
    return items.where((i) => _selectedItemIds.contains(i.id)).length;
  }

  Future<void> _deleteSelected(List<CartItemModel> items) async {
    if (_selectedItemIds.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Belum Ada yang Dipilih',
        description: 'Pilih item yang ingin dihapus terlebih dahulu ya!',
        isError: true,
      );
      return;
    }

    final cubit = context.read<CartCubit>();
    final ids = _selectedItemIds.toList();
    setState(() => _dismissedItemIds.addAll(ids));
    for (final id in ids) {
      await cubit.removeCartItem(id);
    }
    if (mounted) {
      setState(() => _selectedItemIds.clear());
    }
  }

  Future<void> _removeItem(String id) async {
    _markItemRemoved(id);
    await context.read<CartCubit>().removeCartItem(id);
  }

  List<CartItemModel> _visibleItems(List<CartItemModel> items) {
    if (_dismissedItemIds.isEmpty) return items;
    return items.where((item) => !_dismissedItemIds.contains(item.id)).toList();
  }

  void _markItemRemoved(String id) {
    setState(() {
      _dismissedItemIds.add(id);
      _selectedItemIds.remove(id);
    });
  }

  void _proceedToCheckout(List<CartItemModel> items) {
    if (_selectedItemIds.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Belum Ada yang Dipilih',
        description: 'Pilih minimal satu item untuk dicheckout ya!',
        isError: true,
      );
      return;
    }

    final selectedItems =
        items.where((item) => _selectedItemIds.contains(item.id)).toList();
    context.push('/checkout', extra: selectedItems);
  }

  String _formatPrice(double price) {
    return CurrencyFormatter.format(price).replaceFirst('Rp ', 'Rp.');
  }

  Widget _buildCartBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: DamosDominanceColors.textPrimary,
            size: 20,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: DamosDominanceColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPageHeader(int itemCount) {
    return DamosPageHeader(
      title: 'Keranjang saya',
      showBackButton: true,
      onBack: () => CartNavigation.back(context),
      trailing: _buildCartBadge(itemCount),
    );
  }

  Widget _buildQuantitySelector({
    required CartItemModel item,
    required int maxQty,
    required bool enabled,
  }) {
    final quantity = item.quantity;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: DamosDominanceColors.fieldFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyAction(
            icon: quantity > 1 ? Icons.remove : Icons.delete_outline,
            iconColor: quantity > 1
                ? DamosDominanceColors.textPrimary
                : DamosDominanceColors.error,
            onTap: enabled
                ? () {
                    if (quantity > 1) {
                      context.read<CartCubit>().updateQuantity(
                            cartItemId: item.id,
                            quantity: quantity - 1,
                          );
                    } else {
                      _removeItem(item.id);
                    }
                  }
                : null,
          ),
          Container(
            width: 1,
            height: 20,
            color: DamosDominanceColors.fieldBorder,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: DamosDominanceColors.fieldBorder,
          ),
          _qtyAction(
            icon: Icons.add,
            iconColor: DamosDominanceColors.textPrimary,
            onTap: enabled && quantity < maxQty
                ? () {
                    context.read<CartCubit>().updateQuantity(
                          cartItemId: item.id,
                          quantity: quantity + 1,
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _qtyAction({
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 16,
          color: onTap != null ? iconColor : DamosDominanceColors.textHint,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSelectAllHeader(List<CartItemModel> items) {
    final selectableItems = items.where((i) => i.inStock).toList();
    final selectedCount = _selectedCount(items);
    final isAllChecked =
        selectableItems.isNotEmpty && selectedCount == selectableItems.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isAllChecked,
              activeColor: DamosDominanceColors.primary,
              side: const BorderSide(color: DamosDominanceColors.fieldBorder, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => _toggleSelectAll(val, items),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pilih Semua ($selectedCount)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSelected(items),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final isSelected = _selectedItemIds.contains(item.id);
    final maxQty = item.availableStock > 0 ? item.availableStock : 1;
    final enabled = item.inStock;
    final categoryLabel = item.categoryName?.trim().isNotEmpty == true
        ? item.categoryName!
        : (item.variantName ?? '-');

    return Dismissible(
      key: Key('cart-item-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _markItemRemoved(item.id);
        context.read<CartCubit>().removeCartItem(item.id);
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: DamosDominanceColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? DamosDominanceColors.primary.withValues(alpha: 0.45)
              : DamosDominanceColors.fieldBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                activeColor: DamosDominanceColors.primary,
                side: const BorderSide(color: DamosDominanceColors.fieldBorder, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: enabled ? (_) => _toggleSelectItem(item.id) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DamosDominanceColors.fieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        color: DamosDominanceColors.textSecondary,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: DamosDominanceColors.textSecondary,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DamosDominanceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: DamosDominanceColors.error,
                ),
                onPressed: () => _removeItem(item.id),
              ),
              const SizedBox(height: 12),
              _buildQuantitySelector(
                item: item,
                maxQty: maxQty > 0 ? maxQty : 1,
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Keranjangmu masih kosong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yuk, telusuri katalog dan temukan produk kebutuhanmu di koperasi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DamosDominanceColors.primary,
                foregroundColor: DamosDominanceColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Mulai Belanja',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar({
    required int selectedCount,
    required double total,
    required List<CartItemModel> items,
    required bool isUpdating,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Subtotal ($selectedCount Produk)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 12,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: enabled && !isUpdating ? () => _proceedToCheckout(items) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DamosDominanceColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                  disabledForegroundColor: DamosDominanceColors.buttonDisabledText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithScrollHeader(Widget child, {int itemCount = 0}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(itemCount),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartLoaded) {
            final restoredIds = _dismissedItemIds
                .where((id) => state.items.any((item) => item.id == id))
                .toList();
            if (restoredIds.isNotEmpty) {
              setState(() {
                for (final id in restoredIds) {
                  _dismissedItemIds.remove(id);
                }
              });
            }

            if (_selectedItemIds.isEmpty) {
              setState(() {
                for (final item in _visibleItems(state.items)) {
                  if (item.inStock) {
                    _selectedItemIds.add(item.id);
                  }
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return _wrapWithScrollHeader(
              const Padding(
                padding: EdgeInsets.all(16),
                child: ProductGridShimmer(itemCount: 3),
              ),
            );
          }

          if (state is CartError) {
            return _wrapWithScrollHeader(
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<CartCubit>().loadCart(),
                ),
              ),
            );
          }

          if (state is CartLoaded) {
            final items = _visibleItems(state.items);
            final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
            final selectedCount = _selectedCount(items);
            final selectedTotal = _calculateSelectedTotal(items);

            if (items.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeader(0),
                  Expanded(
                    child: Center(
                      child: _buildEmptyState(),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: DamosDominanceColors.primary,
                    onRefresh: () async => context.read<CartCubit>().loadCart(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _buildPageHeader(itemCount),
                        _buildSelectAllHeader(items),
                        ...items.map(_buildCartItem),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutBar(
                  selectedCount: selectedCount,
                  total: selectedTotal,
                  items: items,
                  isUpdating: state.isUpdating,
                  enabled: selectedCount > 0,
                ),
              ],
            );
          }

          return const Center(child: Text('Memuat keranjang...'));
        },
      ),
    );
  }
}
