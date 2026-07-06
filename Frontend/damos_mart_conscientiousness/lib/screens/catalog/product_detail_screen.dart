import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import '../../widgets/common/pop_up_alert.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _red      = Color(0xFFD32F2F);

  int _quantity = 1;
  ProductVariantModel? _selectedVariant;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  double get _displayPrice {
    final product = _product;
    if (product == null) return 0;
    return product.price + (_selectedVariant?.additionalPrice ?? 0);
  }

  ProductModel? get _product {
    final s = context.read<ProductCubit>().state;
    return s is ProductDetailLoaded ? s.product : null;
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      await context.read<CartCubit>().addToCart(
        productId: product.id,
        variantId: _selectedVariant?.id,
        quantity: _quantity,
      );
      if (!mounted) return;
      final s = context.read<CartCubit>().state;
      if (s is CartError) {
        PopUpAlert.show(context: context, title: 'Gagal', description: s.message, isError: true);
        return;
      }
      PopUpAlert.showAddedToCart(context: context, productName: 'Produk Ditambahkan\nKe Keranjang');
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(context: context, title: 'Gagal', description: e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return _buildShimmer();
          if (state is ProductError) return _buildError(state.message);
          if (state is ProductDetailLoaded) return _buildDetail(state);
          return const SizedBox();
        },
      ),
    );
  }

  // ─── DETAIL ───────────────────────────────────────────────────────────────
  Widget _buildDetail(ProductDetailLoaded state) {
    final product = state.product;
    final reviews = state.reviews;

    if (_selectedVariant == null && product.variants.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedVariant == null) {
          setState(() => _selectedVariant = product.variants.first);
        }
      });
    }

    final maxStock = _selectedVariant?.stock ?? product.stock;
    final isOutOfStock = maxStock <= 0 && !product.isPreorder;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ──
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _primary),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.shopping_bag_outlined,
                                size: 80,
                                color: Color(0xFFCCCCCC)),
                          )
                        : const Icon(Icons.shopping_bag_outlined,
                            size: 80, color: Color(0xFFCCCCCC)),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),

                // ── Info ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(product.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          )),
                      const SizedBox(height: 6),

                      // Price
                      Text(CurrencyFormatter.format(_displayPrice),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          )),
                      const SizedBox(height: 10),

                      // Availability badge
                      _buildBadge(product),

                      const SizedBox(height: 24),

                      // Variants (if any)
                      if (product.variants.isNotEmpty) ...[
                        const Text('PILIH UKURAN',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _grey,
                              letterSpacing: 1,
                            )),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.variants.map((v) {
                            final selected = _selectedVariant?.id == v.id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedVariant = v;
                                _quantity = 1;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? _primary : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: selected ? _primary : _border),
                                ),
                                child: Text(v.variantName,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          selected ? Colors.white : _dark,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Quantity
                      if (!isOutOfStock) ...[
                        const Text('JUMLAH PESANAN',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _grey,
                              letterSpacing: 1,
                            )),
                        const SizedBox(height: 10),
                        _buildQtySelector(maxStock),
                        const SizedBox(height: 20),
                      ],

                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 16),

                      // Description
                      const Text('Deskripsi Produk',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        product.description ??
                            'Belum ada deskripsi untuk produk ini.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: _grey,
                          height: 1.6,
                        ),
                      ),


                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom button ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product.isPreorder
                    ? () => context.push('/preorder/${product.id}')
                    : isOutOfStock
                        ? null
                        : () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _border,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  product.isPreorder
                      ? 'Pre-Order Sekarang'
                      : isOutOfStock
                          ? 'Stok Habis'
                          : 'Masukkan Keranjang',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(ProductModel product) {
    final isPreorder  = product.isPreorder;
    final isAvailable = (product.stock > 0) || isPreorder;
    final label = isPreorder ? 'PRE-ORDER' : isAvailable ? 'TERSEDIA' : 'STOK HABIS';
    final color = isAvailable ? _primary : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildQtySelector(int maxStock) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove,
              _quantity > 1 ? () => setState(() => _quantity--) : null),
          SizedBox(
            width: 44,
            child: Text('$_quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _dark)),
          ),
          _qtyBtn(Icons.add,
              _quantity < maxStock ? () => setState(() => _quantity++) : null),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon,
            size: 18, color: onTap != null ? _dark : _border),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>?;
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final comment = review['comment'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user?['fullName'] as String? ?? 'Siswa',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _dark)),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _grey,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(height: 320, color: Colors.white),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 200, color: const Color(0xFFE0E0E0)),
                const SizedBox(height: 10),
                Container(height: 24, width: 120, color: const Color(0xFFE0E0E0)),
                const SizedBox(height: 10),
                Container(height: 30, width: 90, color: const Color(0xFFE0E0E0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: _red),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 14, color: _grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<ProductCubit>().loadProductDetail(widget.productId),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Coba Lagi',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
