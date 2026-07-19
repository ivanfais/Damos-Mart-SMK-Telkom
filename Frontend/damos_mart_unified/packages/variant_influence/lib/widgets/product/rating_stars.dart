import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showText;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.showText = true,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.25 && (rating - fullStars) < 0.75;
    final int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: AppColors.warning, size: size),
        if (hasHalfStar)
          Icon(Icons.star_half, color: AppColors.warning, size: size),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: AppColors.textHint, size: size),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: size * 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
