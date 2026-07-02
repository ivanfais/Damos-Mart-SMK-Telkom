import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../blocs/product/product_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/cart_navigation.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/damos_horizontal_scroll_behavior.dart';
import '../../core/utils/damos_system_ui.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/product/damos_fly_to_cart.dart';
import '../../widgets/product/damos_product_purchase_sheet.dart';
import '../../widgets/product/damos_similar_product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final GlobalKey _productImageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();
  List<ProductModel> _similarProducts = [];
  bool _loadingSimilar = false;
  bool _cartBadgeBounce = false;
  int? _pendingCartCount;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);

    final cartState = context.read<CartCubit>().state;
    if (cartState is! CartLoaded) {
      context.read<CartCubit>().loadCart();
    }
  }

  Future<void> _loadSimilarProducts(ProductModel product) async {
    if (_loadingSimilar) return;
    setState(() => _loadingSimilar = true);

    try {
      final result = await _productRepository.getProducts(
        category: product.categoryId,
        inStock: true,
        limit: 12,
      );
      final products = (result['products'] as List<ProductModel>?) ?? [];
      if (mounted) {
        setState(() {
          _similarProducts =
              products.where((p) => p.id != product.id && p.stock > 0).take(8).toList();
          _loadingSimilar = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  void _openPurchaseSheet(ProductModel product, ProductPurchaseAction action) {
    if (product.isPreorder && product.variants.isEmpty) {
      context.push('/preorder/${product.id}');
      return;
    }

    final cartState = context.read<CartCubit>().state;
    final currentCount = cartState is CartLoaded ? cartState.totalItems : 0;

    DamosProductPurchaseSheet.show(
      context,
      product: product,
      action: action,
      onAddToCartSuccess: action == ProductPurchaseAction.addToCart
          ? () => _playFlyToCart(product, previousCount: currentCount)
          : null,
    );
  }

  Future<void> _playFlyToCart(
    ProductModel product, {
    required int previousCount,
  }) async {
    if (!mounted) return;

    setState(() => _pendingCartCount = previousCount);

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await DamosFlyToCart.animate(
      context: context,
      fromKey: _productImageKey,
      toKey: _cartIconKey,
      imageUrl: product.imageUrl,
      onComplete: () {
        if (!mounted) return;
        setState(() {
          _pendingCartCount = null;
          _cartBadgeBounce = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _cartBadgeBounce = false);
        });
      },
    );
  }

  Widget _sectionDivider() {
    return Container(
      height: 12,
      color: DamosDominanceColors.screenBackground,
    );
  }

  Widget _statusTag({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _overlayIconButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: DamosDominanceColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildImageHeader(ProductModel product, bool isOutOfStock) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Stack(
        children: [
          SizedBox(
            key: _productImageKey,
            height: 300,
            width: double.infinity,
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Icon(Icons.shopping_bag_outlined, size: 64),
                    ),
                  )
                : const ColoredBox(
                    color: Color(0xFFF3F4F6),
                    child: Center(
                      child: Icon(Icons.shopping_bag_outlined, size: 64),
                    ),
                  ),
          ),
          if (isOutOfStock)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: DamosDominanceColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Stok Habis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: _overlayIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            right: 16,
            child: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                final liveCount = state is CartLoaded ? state.totalItems : 0;
                final count = _pendingCartCount ?? liveCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _overlayIconButton(
                      key: _cartIconKey,
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => CartNavigation.open(context),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: AnimatedScale(
                          scale: _cartBadgeBounce ? 1.35 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.elasticOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: Container(
                              key: ValueKey<int>(count),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: const BoxDecoration(
                                color: DamosDominanceColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (!isOutOfStock)
            Positioned(
              right: 16,
              bottom: 16,
              child: BlocBuilder<FavoriteCubit, FavoriteState>(
                builder: (context, _) {
                  final isFavorite =
                      context.read<FavoriteCubit>().isFavorite(product.id);
                  return Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.read<FavoriteCubit>().toggleFavorite(product.id),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? DamosDominanceColors.error : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ProductModel product, bool isOutOfStock) {
    final categoryLabel = product.categoryName.isNotEmpty ? product.categoryName : 'Produk';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusTag(
                label: categoryLabel,
                bg: const Color(0xFFE8F5E9),
                fg: DamosDominanceColors.primary,
              ),
              const Spacer(),
              _statusTag(
                label: isOutOfStock ? 'Habis' : 'Tersedia',
                bg: isOutOfStock
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                fg: isOutOfStock
                    ? DamosDominanceColors.error
                    : DamosDominanceColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(product.price),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ProductModel product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Produk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description ?? 'Belum ada deskripsi untuk produk ini.',
            style: const TextStyle(
              fontSize: 13,
              color: DamosDominanceColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Serupa',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Produk ini habis. Anda bisa coba produk yang lain',
            style: TextStyle(
              fontSize: 12,
              color: DamosDominanceColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: _loadingSimilar
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _similarProducts.isEmpty
                    ? const Text(
                        'Belum ada produk serupa',
                        style: TextStyle(color: DamosDominanceColors.textSecondary),
                      )
                    : ScrollConfiguration(
                        behavior: const DamosHorizontalScrollBehavior(),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _similarProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = _similarProducts[index];
                            return DamosSimilarProductCard(
                              product: item,
                              onTap: () => context.pushReplacement('/catalog/${item.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product, bool isOutOfStock) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: const Color(0xFF6B7280),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'STOK HABIS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Material(
                  color: DamosDominanceColors.primary,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openPurchaseSheet(
                      product,
                      ProductPurchaseAction.buyNow,
                    ),
                    child: const Center(
                      child: Text(
                        'Beli Sekarang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DamosDominanceColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: const Color(0xFFF3F4F6),
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                  side: const BorderSide(
                    color: DamosDominanceColors.primary,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openPurchaseSheet(
                    product,
                    ProductPurchaseAction.addToCart,
                  ),
                  child: SizedBox(
                    width: 56,
                    height: 48,
                    child: Center(child: _cartPlusIcon()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartPlusIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: DamosDominanceColors.primary,
            size: 22,
          ),
          Positioned(
            right: 1,
            bottom: 3,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 10,
                color: DamosDominanceColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded) {
            final product = state.product;
            final isOutOfStock = product.stock <= 0 && !product.isPreorder;
            if (isOutOfStock && _similarProducts.isEmpty && !_loadingSimilar) {
              _loadSimilarProducts(product);
            }
          }
        },
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().loadProductDetail(widget.productId),
            );
          }

          if (state is ProductDetailLoaded) {
            final product = state.product;
            final isOutOfStock = product.stock <= 0 && !product.isPreorder;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageHeader(product, isOutOfStock),
                        _buildInfoSection(product, isOutOfStock),
                        _sectionDivider(),
                        _buildDescriptionSection(product),
                        if (isOutOfStock) ...[
                          _sectionDivider(),
                          _buildSimilarSection(),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(product, isOutOfStock),
              ],
            );
          }

          return const Center(child: Text('Memuat detail produk...'));
        },
      ),
    );
  }
}
