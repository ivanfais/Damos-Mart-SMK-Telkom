import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ProductGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              AspectRatio(
                aspectRatio: 4 / 3,
                child: LoadingShimmer(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppDimensions.cardRadius,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LoadingShimmer(width: 60, height: 16, borderRadius: 4),
                          const SizedBox(height: 8),
                          const LoadingShimmer(width: double.infinity, height: 16, borderRadius: 4),
                          const SizedBox(height: 4),
                          const LoadingShimmer(width: 100, height: 16, borderRadius: 4),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const LoadingShimmer(width: 80, height: 20, borderRadius: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.shimmerBase,
                              shape: BoxShape.circle,
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
        );
      },
    );
  }
}

class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: double.infinity, height: 320, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingShimmer(width: 80, height: 24, borderRadius: 12),
                const SizedBox(height: 16),
                const LoadingShimmer(width: 200, height: 28, borderRadius: 4),
                const SizedBox(height: 12),
                const LoadingShimmer(width: 100, height: 20, borderRadius: 4),
                const SizedBox(height: 16),
                const LoadingShimmer(width: 120, height: 32, borderRadius: 4),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                const LoadingShimmer(width: 150, height: 24, borderRadius: 4),
                const SizedBox(height: 12),
                const LoadingShimmer(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                const LoadingShimmer(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                const LoadingShimmer(width: 250, height: 16, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
