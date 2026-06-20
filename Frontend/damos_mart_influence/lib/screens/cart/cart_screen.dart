import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/cart_item_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color bg = Color(0xFFF9F9F9);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color red = Color(0xFFD42427);
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItemIds = {};

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
        title: 'Belum Ada yang Dipilih ⚠️',
        description: 'Pilih item yang ingin dihapus terlebih dahulu ya!',
        isError: true,
      );
      return;
    }

    final cubit = context.read<CartCubit>();
    final ids = _selectedItemIds.toList();
    for (final id in ids) {
      await cubit.removeCartItem(id);
    }
    if (mounted) {
      setState(() => _selectedItemIds.clear());
    }
  }

  void _proceedToCheckout(List<CartItemModel> items) {
    if (_selectedItemIds.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Oops! 😅',
        description: 'Pilih minimal satu item untuk dicheckout ya! 🛒',
        isError: true,
      );
      return;
    }

    final selectedItems = items.where((item) => _selectedItemIds.contains(item.id)).toList();
    context.push('/checkout', extra: selectedItems);
  }

  Widget _buildQuantitySelector({
    required int quantity,
    required int maxQty,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: _Ds.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(
            icon: Icons.remove,
            onTap: enabled && quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
            ),
          ),
          _qtyBtn(
            icon: Icons.add,
            onTap: enabled && quantity < maxQty ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap}) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: onTap != null ? _Ds.textPrimary : _Ds.border),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final isSelected = _selectedItemIds.contains(item.id);
    final maxQty = item.isPreorder ? 99 : item.availableStock;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              activeColor: _Ds.primary,
              side: const BorderSide(color: _Ds.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: item.inStock ? (_) => _toggleSelectItem(item.id) : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
                ),
                if (item.variantName != null && item.variantName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName!,
                    style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(item.unitPrice),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildQuantitySelector(
            quantity: item.quantity,
            maxQty: maxQty > 0 ? maxQty : 1,
            enabled: item.inStock,
            onChanged: (qty) {
              context.read<CartCubit>().updateQuantity(cartItemId: item.id, quantity: qty);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllHeader(List<CartItemModel> items) {
    final inStockItems = items.where((i) => i.inStock).toList();
    final selectedCount = _selectedCount(items);
    final isAllChecked = inStockItems.isNotEmpty && selectedCount == inStockItems.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isAllChecked,
              activeColor: _Ds.primary,
              side: const BorderSide(color: _Ds.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => _toggleSelectAll(val, items),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pilih Semua ($selectedCount)',
              style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSelected(items),
            child: const Text(
              'Hapus',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtotalRow(int count, double total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Subtotal ($count Produk)',
            style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
          ),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar({
    required double? total,
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
                  const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    total == null ? 'Rp -' : CurrencyFormatter.format(total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
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
                  backgroundColor: _Ds.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _Ds.border,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Checkout',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return const DamosPageHeader(
      title: 'Keranjang Belanja',
      showBackButton: true,
    );
  }

  Widget _wrapWithScrollHeader(Widget child) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartLoaded && _selectedItemIds.isEmpty) {
            setState(() {
              for (final item in state.items) {
                if (item.inStock) {
                  _selectedItemIds.add(item.id);
                }
              }
            });
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
            final items = state.items;

            if (items.isEmpty) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPageHeader(),
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                            child: Center(
                              child: EmptyState(
                                emoji: '🛒',
                                title: 'Belum ada produk di keranjang',
                                subtitle: 'Yuk, mulai belanja dan pilih produk favorit kamu sekarang!',
                                actionButtonText: 'Mulai Belanja',
                                onActionButtonPressed: () => context.go('/catalog'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildCheckoutBar(
                    total: null,
                    items: items,
                    isUpdating: state.isUpdating,
                    enabled: false,
                  ),
                ],
              );
            }

            final selectedCount = _selectedCount(items);
            final selectedTotal = _calculateSelectedTotal(items);

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: _Ds.primary,
                    onRefresh: () async => context.read<CartCubit>().loadCart(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildPageHeader(),
                        _buildSelectAllHeader(items),
                        const SizedBox(height: 2),
                        ...List.generate(items.length, (index) {
                          return Column(
                            children: [
                              _buildCartItem(items[index]),
                              if (index < items.length - 1) const SizedBox(height: 8),
                            ],
                          );
                        }),
                        const SizedBox(height: 8),
                        _buildSubtotalRow(selectedCount, selectedTotal),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutBar(
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
