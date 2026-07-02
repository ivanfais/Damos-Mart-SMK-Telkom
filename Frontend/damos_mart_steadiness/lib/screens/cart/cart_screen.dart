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
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color bgGrey = Color(0xFFF3F4F6);
  static const double adminFee = 500;
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  int _totalQuantity(List<CartItemModel> items) {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double _subtotal(List<CartItemModel> items) {
    return items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  double _grandTotal(List<CartItemModel> items) {
    return _subtotal(items) + _Ds.adminFee;
  }

  List<CartItemModel> _validItems(List<CartItemModel> items) {
    return items.where((item) => item.inStock || item.isPreorder).toList();
  }

  void _proceedToCheckout(List<CartItemModel> items) {
    final validItems = _validItems(items);
    if (validItems.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Keranjang Kosong',
        description: 'Tidak ada produk yang bisa diproses. Tambahkan produk ke keranjang dulu ya!',
        isError: true,
      );
      return;
    }
    context.push('/checkout', extra: validItems);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _Ds.textSecondary,
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: _Ds.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? _Ds.textPrimary : _Ds.border,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector({
    required int quantity,
    required int maxQty,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qtyButton(
          icon: Icons.remove,
          onTap: enabled && quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        const SizedBox(width: 6),
        Container(
          width: 36,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: _Ds.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
          ),
        ),
        const SizedBox(width: 6),
        _qtyButton(
          icon: Icons.add,
          onTap: enabled && quantity < maxQty ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final maxQty = item.isPreorder ? 99 : item.availableStock;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Ds.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 28),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 28),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _Ds.textPrimary,
                    height: 1.3,
                  ),
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
                  style: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuantitySelector(
                      quantity: item.quantity,
                      maxQty: maxQty > 0 ? maxQty : 1,
                      enabled: item.inStock || item.isPreorder,
                      onChanged: (qty) {
                        context.read<CartCubit>().updateQuantity(cartItemId: item.id, quantity: qty);
                      },
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(item.subtotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _Ds.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupMethod() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: _Ds.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
          SizedBox(height: 8),
          Text(
            'Ambil di Koperasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItemModel> items) {
    final qty = _totalQuantity(items);
    final subtotal = _subtotal(items);
    final total = _grandTotal(items);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal ($qty Produk)', CurrencyFormatter.format(subtotal)),
          const SizedBox(height: 8),
          _summaryRow('Biaya Admin', CurrencyFormatter.format(_Ds.adminFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _Ds.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
      ],
    );
  }

  Widget _buildCheckoutButton({
    required List<CartItemModel> items,
    required bool enabled,
    required bool isUpdating,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: enabled && !isUpdating ? () => _proceedToCheckout(items) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Ds.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _Ds.border,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Lanjut ke Pembayaran',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Column(
              children: [
                const SteadinessAppHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ProductGridShimmer(itemCount: 3),
                  ),
                ),
              ],
            );
          }

          if (state is CartError) {
            return Column(
              children: [
                const SteadinessAppHeader(),
                Expanded(
                  child: ErrorState(
                    message: state.message,
                    onRetry: () => context.read<CartCubit>().loadCart(),
                  ),
                ),
              ],
            );
          }

          if (state is! CartLoaded) {
            return const Center(child: CircularProgressIndicator(color: _Ds.primary));
          }

          final items = _validItems(state.items);

          if (items.isEmpty) {
            return Column(
              children: [
                const SteadinessAppHeader(),
                Expanded(
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
                _buildCheckoutButton(items: items, enabled: false, isUpdating: state.isUpdating),
              ],
            );
          }

          return Column(
            children: [
              const SteadinessAppHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: _Ds.primary,
                  onRefresh: () async => context.read<CartCubit>().loadCart(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _sectionTitle('Daftar Produk'),
                      ...List.generate(items.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
                          child: _buildCartItem(items[index]),
                        );
                      }),
                      const SizedBox(height: 22),
                      _sectionTitle('Metode Pengambilan'),
                      _buildPickupMethod(),
                      const SizedBox(height: 22),
                      _buildOrderSummary(items),
                    ],
                  ),
                ),
              ),
              _buildCheckoutButton(
                items: items,
                enabled: items.isNotEmpty,
                isUpdating: state.isUpdating,
              ),
            ],
          );
        },
      ),
    );
  }
}
