import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/cart_item_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';

class ProductListTile extends StatelessWidget {
  final CartItemModel item;
  final bool isEditable;
  final bool isSelected;
  final void Function(bool?)? onSelectedChanged;
  final void Function(int)? onQuantityChanged;
  final VoidCallback? onDelete;

  const ProductListTile({
    super.key,
    required this.item,
    this.isEditable = true,
    this.isSelected = false,
    this.onSelectedChanged,
    this.onQuantityChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Select Checkbox (Cart only)
          if (isEditable && onSelectedChanged != null) ...[
            Checkbox(
              value: isSelected,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onSelectedChanged,
            ),
            const SizedBox(width: 4),
          ],
          
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: SizedBox(
              width: 70,
              height: 70,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primarySurface,
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                
                // Variant & Preorder label
                if (item.variantName != null || item.isPreorder) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.variantName != null)
                        Text(
                          'Varian: ${item.variantName} 👕',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.variantName != null && item.isPreorder)
                        const SizedBox(width: 8),
                      if (item.isPreorder)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: Text(
                            'Pre-Order 📦',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Low-stock indicator (seperti aplikasi e-commerce umumnya)
                if (!item.isPreorder && item.availableStock < 10) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item.availableStock <= 0 ? AppColors.error : AppColors.warning)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.availableStock <= 0
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.local_fire_department_rounded,
                          size: 12,
                          color: item.availableStock <= 0 ? AppColors.error : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.availableStock <= 0
                              ? 'Stok habis'
                              : 'Stok tinggal ${item.availableStock} lagi!',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: item.availableStock <= 0 ? AppColors.error : AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                
                // Price & actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.unitPrice),
                      style: AppTextStyles.priceSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    
                    // Quantity management
                    if (isEditable && onQuantityChanged != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider, width: 1.2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (item.quantity > 1) {
                                  onQuantityChanged!(item.quantity - 1);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Icon(Icons.remove, size: 14, color: AppColors.primary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${item.quantity}',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (item.quantity < item.availableStock || item.isPreorder) {
                                  onQuantityChanged!(item.quantity + 1);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Icon(Icons.add, size: 14, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Read-only quantity indicator
                      Text(
                        'x ${item.quantity}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Delete button (Cart only)
          if (isEditable && onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
