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
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFD42427);
  static const Color star = Color(0xFFFFC107);
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

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  void _incrementQty(int maxStock) {
    if (_quantity < maxStock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  double _displayPrice(ProductModel product) {
    var price = product.price;
    if (_selectedVariant != null) {
      price += _selectedVariant!.additionalPrice;
    }
    return price;
  }

  Future<void> _addToCart(ProductModel product) async {
    final cartCubit = context.read<CartCubit>();

    try {
      await cartCubit.addToCart(
        productId: product.id,
        variantId: _selectedVariant?.id,
        quantity: _quantity,
      );
      if (!mounted) return;

      final cartState = cartCubit.state;
      if (cartState is CartError) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Menambahkan',
          description: 'Gagal menambahkan ke keranjang: ${cartState.message}',
          isError: true,
        );
        return;
      }

      PopUpAlert.showAddedToCart(context: context, productName: product.name);
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Menambahkan',
        description: 'Gagal menambahkan ke keranjang: ${e.toString()}',
        isError: true,
      );
    }
  }

  Widget _buildScrollHeader() {
    return DamosPageHeader(
      title: 'Damos Mart',
      showBackButton: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.go('/catalog'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.go('/cart'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollPage(Widget child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScrollHeader(),
          child,
        ],
      ),
    );
  }

  Widget _buildRatingRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: _Ds.star, size: 20),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
        ),
      ],
    );
  }

  Widget _buildAvailabilityBadge({required bool available, required bool isPreorder}) {
    if (isPreorder) {
      return _availabilityBadge('PRE-ORDER', _Ds.primary);
    }
    if (available) {
      return _availabilityBadge('TERSEDIA', _Ds.primary);
    }
    return _availabilityBadge('STOK HABIS', _Ds.red);
  }

  Widget _availabilityBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _Ds.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _Ds.primary : _Ds.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _Ds.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector({required int maxStock, required bool enabled}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _Ds.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(
            icon: Icons.remove,
            onTap: enabled && _quantity > 1 ? _decrementQty : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
            ),
          ),
          _qtyButton(
            icon: Icons.add,
            onTap: enabled && _quantity < maxStock ? () => _incrementQty(maxStock) : null,
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: onTap != null ? _Ds.textPrimary : _Ds.border),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>?;
    final ratingVal = (review['rating'] as num?)?.toInt() ?? 5;
    final comment = review['comment'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user?['fullName'] as String? ?? 'Siswa',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < ratingVal ? Icons.star : Icons.star_border,
                    size: 16,
                    color: _Ds.star,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductHeroImage({required String? imageUrl, required bool isOutOfStock}) {
    const height = 320.0;

    final Widget imageContent = imageUrl != null && imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: ApiConfig.imageUrl(imageUrl),
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (_, __) => Container(
              color: _Ds.bgGrey,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _Ds.primary,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: _Ds.bgGrey,
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: _Ds.textSecondary,
                size: 64,
              ),
            ),
          )
        : Container(
            color: _Ds.bgGrey,
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: _Ds.textSecondary,
              size: 64,
            ),
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageContent,
          if (isOutOfStock) ...[
            ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _Ds.greenLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Ds.primary.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'STOK HABIS',
                  style: TextStyle(
                    color: _Ds.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required ProductModel product,
    required bool isOutOfStock,
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
              backgroundColor: _Ds.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _Ds.border,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              product.isPreorder ? 'Pre-Order Sekarang' : 'Masukkan Keranjang',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return _buildScrollPage(const ProductDetailShimmer());
          }

          if (state is ProductError) {
            return _buildScrollPage(
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<ProductCubit>().loadProductDetail(widget.productId),
                ),
              ),
            );
          }

          if (state is ProductDetailLoaded) {
            final product = state.product;

            if (product.isPreorder) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.replace('/preorder/${product.id}');
                }
              });
              return const Center(child: CircularProgressIndicator(color: _Ds.primary));
            }

            final reviews = state.reviews;

            if (_selectedVariant == null && product.variants.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedVariant == null) {
                  setState(() => _selectedVariant = product.variants.first);
                }
              });
            }

            final currentMaxStock = _selectedVariant?.stock ?? product.stock;
            final isOutOfStock = currentMaxStock <= 0 && !product.isPreorder;
            final isAvailable = !isOutOfStock;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScrollHeader(),
                        _buildProductHeroImage(
                          imageUrl: ProductVariantModel.displayImageUrl(
                            productImageUrl: product.imageUrl,
                            variant: _selectedVariant,
                          ),
                          isOutOfStock: isOutOfStock,
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + rating
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _Ds.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _buildRatingRow(product.averageRating),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Price
                              Text(
                                CurrencyFormatter.format(_displayPrice(product)),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _Ds.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Availability badge
                              _buildAvailabilityBadge(
                                available: isAvailable,
                                isPreorder: product.isPreorder,
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: _Ds.borderLight),
                              const SizedBox(height: 12),

                              // Description
                              const Text(
                                'Deskripsi Produk',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description ?? 'Belum ada deskripsi untuk produk ini.',
                                style: const TextStyle(fontSize: 14, color: _Ds.textSecondary, height: 1.5),
                              ),

                              if (product.variants.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'PILIH UKURAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _Ds.textSecondary,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: product.variants.map((variant) {
                                    final selected = _selectedVariant?.id == variant.id;
                                    return _buildSizeChip(
                                      label: variant.variantName,
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          _selectedVariant = variant;
                                          _quantity = 1;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],

                              if (isAvailable) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'JUMLAH PESANAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _Ds.textSecondary,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildQuantitySelector(maxStock: currentMaxStock, enabled: true),
                              ],

                              const SizedBox(height: 28),

                              // Reviews header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ulasan Pengguna (${product.totalReviews})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _Ds.textPrimary,
                                    ),
                                  ),
                                  if (reviews.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {},
                                      child: const Text(
                                        'Lihat Semua',
                                        style: TextStyle(fontSize: 14, color: _Ds.primary),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (reviews.isEmpty)
                                const Text(
                                  'Belum ada ulasan untuk produk ini.',
                                  style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reviews.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final review = reviews[index] as Map<String, dynamic>;
                                    return _buildReviewCard(review);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildBottomBar(product: product, isOutOfStock: isOutOfStock),
              ],
            );
          }

          return const Center(child: Text('Memuat detail produk...'));
        },
      ),
    );
  }
}
