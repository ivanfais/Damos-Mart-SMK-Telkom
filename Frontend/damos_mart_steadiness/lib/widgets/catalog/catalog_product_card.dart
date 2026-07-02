import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../data/models/product_model.dart';
import '../common/steadiness_app_header.dart';

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onBuy,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _imageBg = Color(0xFFF8F8F8);
  static const Color _red = Color(0xFFD42427);

  String _formatPrice(double price) {
    return CurrencyFormatter.format(price).replaceFirst('Rp ', 'Rp');
  }

  String _categoryLabel() {
    return product.categoryName.isNotEmpty ? product.categoryName : 'Produk';
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = ProductGridLayout.itemWidth(context) * 0.92;
    final hasStock = product.stock > 0 || product.isPreorder;
    final isLowStock = !product.isPreorder && product.stock > 0 && product.stock <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: imageHeight,
              child: ColoredBox(
                color: _imageBg,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SteadinessHeaderColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.shopping_bag_outlined, color: _textSecondary, size: 32),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: _textSecondary, size: 32),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryLabel(),
                        style: const TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: SteadinessHeaderColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.isPreorder
                            ? 'Pre-Order'
                            : 'Stok: ${product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.isPreorder
                              ? _textSecondary
                              : (isLowStock ? _red : _textSecondary),
                          fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: hasStock ? onBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SteadinessHeaderColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _textSecondary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Beli', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
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
