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
                  child: ColoredBox(
                    color: const Color(0xFFF3F4F6),
                    child: SizedBox(
                      width: double.infinity,
                      height: 90,
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.shopping_bag_outlined,
                                color: DamosDominanceColors.textHint,
                              ),
                            )
                          : const Icon(
                              Icons.shopping_bag_outlined,
                              color: DamosDominanceColors.textHint,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
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
