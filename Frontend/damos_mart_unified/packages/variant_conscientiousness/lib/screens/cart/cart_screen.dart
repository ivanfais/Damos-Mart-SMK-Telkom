import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/cart_item_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/pop_up_alert.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _red      = Color(0xFFD32F2F);

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  void _toggleItem(String id) =>
      setState(() => _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id));

  void _toggleAll(bool? select, List<CartItemModel> items) {
    setState(() {
      if (select == true) {
        _selectedIds
          ..clear()
          ..addAll(items.where((i) => i.inStock || i.isPreorder).map((i) => i.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  double _total(List<CartItemModel> items) =>
      items.where((i) => _selectedIds.contains(i.id)).fold(0.0, (s, i) => s + i.subtotal);

  int _selectedCount(List<CartItemModel> items) =>
      items.where((i) => _selectedIds.contains(i.id)).length;

  Future<void> _deleteSelected(List<CartItemModel> items) async {
    if (_selectedIds.isEmpty) {
      PopUpAlert.show(
          context: context,
          title: 'Belum Ada yang Dipilih',
          description: 'Pilih item yang ingin dihapus terlebih dahulu.',
          isError: true);
      return;
    }
    final cubit = context.read<CartCubit>();
    for (final id in _selectedIds.toList()) await cubit.removeCartItem(id);
    if (mounted) setState(() => _selectedIds.clear());
  }

  void _checkout(List<CartItemModel> items) {
    if (_selectedIds.isEmpty) return;
    final selected = items.where((i) => _selectedIds.contains(i.id)).toList();
    context.push('/checkout', extra: selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartLoaded && _selectedIds.isEmpty) {
            setState(() {
              for (final item in state.items) {
                if (item.inStock) _selectedIds.add(item.id);
              }
            });
          }
        },
        builder: (context, state) {
          final items = state is CartLoaded ? state.items : <CartItemModel>[];
          final isUpdating = state is CartLoaded ? state.isUpdating : false;
          final isLoading = state is CartLoading;
          final selCount = _selectedCount(items);
          final selTotal = _total(items);
          final canCheckout = selCount > 0 && !isUpdating;

          return Column(
            children: [
              // ── Header ──
              _buildHeader(),

              // ── Select All + Hapus ──
              _buildSelectAllBar(items, selCount),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),

              // ── Subtotal row ──
              _buildSubtotalRow(selCount, selTotal),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),

              // ── Items / Empty / Loading ──
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF018D1A)))
                    : items.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _primary,
                            onRefresh: () async =>
                                context.read<CartCubit>().loadCart(),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildCartItem(items[i]),
                            ),
                          ),
              ),

              // ── Checkout bar ──
              _buildCheckoutBar(selTotal, canCheckout, items),
            ],
          );
        },
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(AppConstants.imageLogo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                          color: Colors.white24, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('DM',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    )),
          ),
          const SizedBox(width: 12),
          const Text('Damos Mart',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ─── SELECT ALL BAR ───────────────────────────────────────────────────────
  Widget _buildSelectAllBar(List<CartItemModel> items, int selCount) {
    final inStockItems = items.where((i) => i.inStock || i.isPreorder).toList();
    final isAllChecked =
        inStockItems.isNotEmpty && selCount == inStockItems.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isAllChecked,
              activeColor: _primary,
              side: BorderSide(color: _border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: items.isEmpty ? null : (v) => _toggleAll(v, items),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pilih Semua ($selCount)',
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF111111)),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSelected(items),
            child: Text(
              'Hapus',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _red),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUBTOTAL ROW ─────────────────────────────────────────────────────────
  Widget _buildSubtotalRow(int count, double total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Subtotal ($count Produk)',
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF555555))),
          Text(CurrencyFormatter.format(total),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text('Keranjang masih kosong',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555))),
          SizedBox(height: 6),
          Text('Tambahkan produk dari katalog',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  // ─── CART ITEM ────────────────────────────────────────────────────────────
  Widget _buildCartItem(CartItemModel item) {
    final isSelected = _selectedIds.contains(item.id);
    final maxQty = item.isPreorder ? 99 : item.availableStock;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isSelected,
              activeColor: _primary,
              side: BorderSide(color: _border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (item.inStock || item.isPreorder)
                  ? (_) => _toggleItem(item.id)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF0F0F0),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFFCCCCCC),
                          size: 24),
                    )
                  : const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFFCCCCCC), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111))),
                if (item.variantName != null && item.variantName!.isNotEmpty)
                  Text(item.variantName!,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF888888))),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(item.unitPrice),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildQtySelector(item, maxQty),
        ],
      ),
    );
  }

  Widget _buildQtySelector(CartItemModel item, int maxQty) {
    final qty = item.quantity;
    final enabled = item.inStock || item.isPreorder;
    return Container(
      height: 32,
      decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove,
              enabled && qty > 1
                  ? () => context.read<CartCubit>().updateQuantity(
                      cartItemId: item.id, quantity: qty - 1)
                  : null),
          SizedBox(
            width: 28,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          _qtyBtn(Icons.add,
              enabled && qty < (maxQty > 0 ? maxQty : 1)
                  ? () => context.read<CartCubit>().updateQuantity(
                      cartItemId: item.id, quantity: qty + 1)
                  : null),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => SizedBox(
        width: 30,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon,
              size: 14,
              color: onTap != null ? _dark : _border),
          onPressed: onTap,
        ),
      );

  // ─── CHECKOUT BAR ─────────────────────────────────────────────────────────
  Widget _buildCheckoutBar(
      double total, bool canCheckout, List<CartItemModel> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Pembayaran',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF888888))),
                  const SizedBox(height: 2),
                  Text(CurrencyFormatter.format(total),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 46,
              width: 150,
              child: ElevatedButton(
                onPressed: canCheckout ? () => _checkout(items) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: Colors.white,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: _grey,
                  elevation: 0,
                  side: canCheckout
                      ? BorderSide.none
                      : BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Checkout',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
