import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/product_stock_utils.dart';
import '../../data/models/product_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../common/loading_shimmer.dart';

/// Horizontal product card for Beranda carousels — 165 x 230.
class DamosHomeProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const DamosHomeProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  static const double cardWidth = 165;
  static const double cardHeight = 230;

  @override
  Widget build(BuildContext context) {
    final hasStock = ProductStockUtils.hasAvailableStock(product);

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColoredBox(
                        color: const Color(0xFFF3F4F6),
                        child: SizedBox(
                          width: cardWidth - 20,
                          height: 130,
                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const DamosImagePlaceholderShimmer(),
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: DamosDominanceColors.textHint,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: DamosDominanceColors.textHint,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavoriteTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 25,
                            color: isFavorite
                                ? DamosDominanceColors.error
                                : DamosDominanceColors.textPrimary
                                    .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                    if (!hasStock)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.white.withOpacity(0.65),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DamosDominanceColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Habis',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (product.categoryName.isNotEmpty)
                  Text(
                    product.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        CurrencyFormatter.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DamosDominanceColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      product.isPreorder
                          ? (hasStock ? 'Pre-Order' : 'Kuota Habis')
                          : hasStock
                              ? 'Tersedia'
                              : 'Habis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasStock
                            ? DamosDominanceColors.primary
                            : DamosDominanceColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
