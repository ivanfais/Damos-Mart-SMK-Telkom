import 'package:flutter/material.dart';

/// Responsive 2-column product grid with compact card height for mobile.
class ProductGridLayout {
  static SliverGridDelegate responsiveDelegate(
    BuildContext context, {
    double horizontalPadding = 32,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    const crossAxisCount = 2;
    const spacing = 10.0;
    final totalSpacing = spacing * (crossAxisCount - 1);
    final itemWidth = (width - horizontalPadding - totalSpacing) / crossAxisCount;
    final imageHeight = itemWidth * 0.92;
    const contentHeight = 118.0;
    final mainAxisExtent = imageHeight + contentHeight;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: mainAxisExtent,
    );
  }

  static SliverGridDelegate responsiveSliverDelegate(
    BuildContext context, {
    double horizontalPadding = 32,
  }) {
    return responsiveDelegate(context, horizontalPadding: horizontalPadding);
  }
}
