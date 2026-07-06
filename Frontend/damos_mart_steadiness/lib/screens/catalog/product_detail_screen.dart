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
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bgGrey = Color(0xFFF5F5F5);
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariantModel? _selectedVariant;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  void _incrementQty(int maxStock) {
    if (_quantity < maxStock) setState(() => _quantity++);
  }

  void _decrementQty() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  double _displayPrice(ProductModel product) {
    var price = product.price;
    if (_selectedVariant != null) {
      price += _selectedVariant!.additionalPrice;
    }
    return price;
  }

  int _displayStock(ProductModel product) {
    return _selectedVariant?.stock ?? product.stock;
  }

  Future<bool> _addToCart(ProductModel product, {bool silent = false}) async {
    if (_isAdding) return false;
    setState(() => _isAdding = true);

    final cartCubit = context.read<CartCubit>();
    try {
      await cartCubit.addToCart(
        productId: product.id,
        variantId: _selectedVariant?.id,
        quantity: _quantity,
      );
      if (!mounted) return false;

      final cartState = cartCubit.state;
      if (cartState is CartError) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Menambahkan',
          description: 'Gagal menambahkan ke keranjang: ${cartState.message}',
          isError: true,
        );
        return false;
      }

      if (!silent) {
        PopUpAlert.showAddedToCart(context: context, productName: product.name);
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Menambahkan',
        description: 'Gagal menambahkan ke keranjang: ${e.toString()}',
        isError: true,
      );
      return false;
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _continueShopping(ProductModel product) {
    if (product.isPreorder) {
      context.push('/preorder/${product.id}');
      return;
    }
    context.go('/catalog');
  }

  Widget _buildProductImage(ProductModel product) {
    return Container(
      width: double.infinity,
      height: 280,
      color: Colors.white,
      alignment: Alignment.center,
      child: product.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(product.imageUrl!),
              width: double.infinity,
              height: 220,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _Ds.primary),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.shopping_bag_outlined,
                color: _Ds.textSecondary,
                size: 64,
              ),
            )
          : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 64),
    );
  }

  Widget _buildVariantChips(ProductModel product) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Pilih Varian',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.variants.map((variant) {
            final selected = _selectedVariant?.id == variant.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedVariant = variant;
                _quantity = 1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _Ds.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? _Ds.primary : _Ds.border),
                ),
                child: Text(
                  variant.variantName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _Ds.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper({required int maxStock, required bool enabled}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove,
          onTap: enabled && _quantity > 1 ? _decrementQty : null,
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: _Ds.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_quantity',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        _stepperButton(
          icon: Icons.add,
          onTap: enabled && _quantity < maxStock ? () => _incrementQty(maxStock) : null,
        ),
      ],
    );
  }

  Widget _stepperButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: _Ds.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? _Ds.textPrimary : _Ds.border,
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required ProductModel product,
    required bool isOutOfStock,
    required int maxStock,
  }) {
    final enabled = !isOutOfStock || product.isPreorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jumlah Pembelian',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
                if (enabled && !product.isPreorder)
                  _buildQuantityStepper(maxStock: maxStock, enabled: true)
                else
                  Text(
                    product.isPreorder ? 'Pre-Order' : 'Habis',
                    style: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: !enabled || _isAdding
                    ? null
                    : product.isPreorder
                        ? () => context.push('/preorder/${product.id}')
                        : () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Ds.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _Ds.border,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.shopping_cart_outlined, size: 20),
                label: Text(
                  product.isPreorder ? 'Pre-Order Sekarang' : 'Tambah ke Keranjang',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isAdding ? null : () => _continueShopping(product),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Ds.textPrimary,
                  side: const BorderSide(color: _Ds.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  product.isPreorder ? 'Lihat Detail Pre-Order' : 'Lanjut Belanja',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SteadinessAppHeader(
      showNotificationButton: false,
      showCartButton: true,
      onCartTap: () => context.go('/cart'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(child: ProductDetailShimmer()),
              ],
            );
          }

          if (state is ProductError) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ErrorState(
                    message: state.message,
                    onRetry: () => context.read<ProductCubit>().loadProductDetail(widget.productId),
                  ),
                ),
              ],
            );
          }

          if (state is! ProductDetailLoaded) {
            return const Center(child: CircularProgressIndicator(color: _Ds.primary));
          }

          final product = state.product;

          if (product.isPreorder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.replace('/preorder/${product.id}');
            });
            return Column(
              children: [
                _buildHeader(),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: _Ds.primary),
                  ),
                ),
              ],
            );
          }

          if (_selectedVariant == null && product.variants.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedVariant == null) {
                setState(() => _selectedVariant = product.variants.first);
              }
            });
          }

          final currentMaxStock = _displayStock(product);
          final isOutOfStock = currentMaxStock <= 0 && !product.isPreorder;

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(product),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _Ds.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(_displayPrice(product)),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _Ds.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _Ds.bgGrey,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _Ds.border),
                              ),
                              child: Text(
                                'Stok: ${product.isPreorder ? 'Pre-Order' : currentMaxStock}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _Ds.textPrimary,
                                ),
                              ),
                            ),
                            _buildVariantChips(product),
                            const SizedBox(height: 20),
                            const Divider(color: _Ds.border, height: 1),
                            const SizedBox(height: 18),
                            const Text(
                              'Deskripsi Produk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _Ds.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.description ?? 'Belum ada deskripsi untuk produk ini.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _Ds.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: _Ds.border, height: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(
                product: product,
                isOutOfStock: isOutOfStock,
                maxStock: currentMaxStock,
              ),
            ],
          );
        },
      ),
    );
  }
}
