import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../data/models/product_model.dart';

/// Compact product card for home/catalog grids.
class DamosProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const DamosProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  static const Color _primary = Color(0xFF1B8C2E);
  static const Color _greenLight = Color(0xFFE8F5E9);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _hint = Color(0xFF9CA3AF);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _bgGrey = Color(0xFFF2F2F2);
  static const Color _red = Color(0xFFD42427);
  static const Color _star = Color(0xFFFFC107);
  static const Color _soldOutButton = Color(0xFF9CCC9C);

  Widget _buildProductImage(double height, {required bool dimmed}) {
    final displayImageUrl = product.displayImageUrl();
    final Widget imageContent = displayImageUrl != null && displayImageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: ApiConfig.imageUrl(displayImageUrl),
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            placeholder: (_, __) => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              ),
            ),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.shopping_bag_outlined, color: _hint, size: 30),
            ),
          )
        : const Center(
            child: Icon(Icons.shopping_bag_outlined, color: _hint, size: 30),
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: _bgGrey,
        child: dimmed
            ? Stack(
                fit: StackFit.expand,
                children: [
                  imageContent,
                  ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                ],
              )
            : imageContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreorder = product.isPreorder;
    final bool isOutOfStock = !isPreorder && product.stock <= 0;
    final bool hasStock = !isPreorder && product.stock > 0;
    final bool canOrder = isPreorder || hasStock;
    final String availabilityLabel = isPreorder
        ? 'Pre-Order'
        : isOutOfStock
            ? 'Stok Habis'
            : 'Tersedia';
    final Color availabilityColor = isOutOfStock ? _red : _primary;
    final imageHeight = ProductGridLayout.imageHeight(context);

    return SizedBox(
      height: ProductGridLayout.cardHeight(context),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                _buildProductImage(imageHeight, dimmed: isOutOfStock),
                if (product.categoryName.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _greenLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                if (isPreorder)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRE-ORDER',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _greenLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _primary.withValues(alpha: 0.25)),
                        ),
                        child: const Text(
                          'STOK HABIS',
                          style: TextStyle(
                            color: _red,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: _star, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10, color: _textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              availabilityLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: availabilityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: canOrder
                      ? ElevatedButton(
                          onPressed: onAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            isPreorder ? 'Pre-Order' : 'Add to Cart',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: _soldOutButton,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
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
