import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import 'rating_stars.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = AppAnimations.cardScaleValue;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasStock = widget.product.stock > 0 || widget.product.isPreorder;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: AppAnimations.cardScale,
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: AppColors.surface,
                        child: widget.product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: ApiConfig.imageUrl(widget.product.imageUrl!),
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primarySurface,
                                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 40),
                                ),
                              )
                            : Container(
                                color: AppColors.primarySurface,
                                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 40),
                              ),
                      ),
                    ),
                    // Preorder Tag
                    if (widget.product.isPreorder)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: Text(
                            'Pre-Order 📦',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category and Name (flexible so it shrinks instead of overflowing)
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Category Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                ),
                                child: Text(
                                  widget.product.categoryName,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Product Name
                              Flexible(
                                child: Text(
                                  widget.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Rating & Stock
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingStars(rating: widget.product.averageRating, size: 12),
                            const SizedBox(height: 4),
                            // Stock Status
                            Text(
                              hasStock ? 'Tersedia ✅' : 'Stok Habis 😔',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: hasStock ? AppColors.inStock : AppColors.outOfStock,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Price and Cart Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                CurrencyFormatter.format(widget.product.price),
                                style: AppTextStyles.priceSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (hasStock)
                              GestureDetector(
                                onTap: widget.onAddToCart,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
