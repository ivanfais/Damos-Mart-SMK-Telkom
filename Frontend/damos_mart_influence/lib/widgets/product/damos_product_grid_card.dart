import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool hasStock = product.stock > 0 || product.isPreorder;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: _bgGrey,
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
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
                          ),
                  ),
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
                  if (!hasStock)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STOK HABIS',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
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
                              hasStock ? 'Tersedia' : 'Stok Habis',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: hasStock ? _primary : _red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: hasStock
                      ? OutlinedButton(
                          onPressed: onAddToCart,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: _hint,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
