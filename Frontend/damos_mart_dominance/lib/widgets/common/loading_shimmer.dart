import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../catalog/damos_catalog_product_card.dart';

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
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: ProductGridLayout.responsiveDelegate(context),
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

/// 2-column product card grid shimmer for catalog, favorites, and search.
class DamosCatalogProductGridShimmer extends StatelessWidget {
  const DamosCatalogProductGridShimmer({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  static SliverGridDelegate get gridDelegate =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: DamosCatalogProductCard.cardHeight,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: (_, __) => const LoadingShimmer(
          width: DamosCatalogProductCard.cardWidth,
          height: DamosCatalogProductCard.cardHeight,
          borderRadius: 8,
        ),
      ),
    );
  }
}

/// List of white card shimmers for notifications, complaints, queues, etc.
class DamosListCardShimmer extends StatelessWidget {
  const DamosListCardShimmer({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(width: 120, height: 14, borderRadius: 4),
            SizedBox(height: 10),
            LoadingShimmer(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 8),
            LoadingShimmer(width: 80, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Profile settings page skeleton.
class DamosProfileShimmer extends StatelessWidget {
  const DamosProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LoadingShimmer(width: double.infinity, height: 120, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      LoadingShimmer(width: 56, height: 56, borderRadius: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoadingShimmer(width: 140, height: 16, borderRadius: 4),
                            SizedBox(height: 8),
                            LoadingShimmer(width: 180, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: const LoadingShimmer(width: 160, height: 14, borderRadius: 4),
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

/// Chat room loading skeleton.
class DamosChatShimmer extends StatelessWidget {
  const DamosChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _bubble(width: 220),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _bubble(width: 180),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _bubble(width: 260),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _bubble(width: 200),
        ),
      ],
    );
  }

  Widget _bubble({required double width}) {
    return LoadingShimmer(width: width, height: 48, borderRadius: 16);
  }
}

/// Order / payment detail page skeleton.
class DamosOrderDetailShimmer extends StatelessWidget {
  const DamosOrderDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LoadingShimmer(width: double.infinity, height: 88, borderRadius: 12),
          const SizedBox(height: 16),
          const LoadingShimmer(width: double.infinity, height: 180, borderRadius: 12),
          const SizedBox(height: 16),
          const LoadingShimmer(width: double.infinity, height: 120, borderRadius: 12),
          const SizedBox(height: 16),
          const LoadingShimmer(width: double.infinity, height: 48, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Full-width image placeholder shimmer.
class DamosImagePlaceholderShimmer extends StatelessWidget {
  const DamosImagePlaceholderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingShimmer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
    );
  }
}
