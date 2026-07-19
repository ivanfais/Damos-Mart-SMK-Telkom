import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../../theme/damos_dominance_colors.dart';

/// Compact card for "Produk Serupa" horizontal list.
class DamosSimilarProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const DamosSimilarProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  static const double cardWidth = 120;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = product.displayImageUrl();

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 90,
                    child: Stack(
                      children: [
                        ColoredBox(
                          color: const Color(0xFFF3F4F6),
                          child: displayImageUrl != null && displayImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ApiConfig.imageUrl(displayImageUrl),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 90,
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: DamosDominanceColors.textHint,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: DamosDominanceColors.textHint,
                                  ),
                                ),
                        ),
                        if (product.stock <= 0)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withOpacity(0.65),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DamosDominanceColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Habis',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
