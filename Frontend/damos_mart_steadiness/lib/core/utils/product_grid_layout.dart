import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive 2-column product grid sized for mobile (~430px max).
class ProductGridLayout {
  static const double maxLayoutWidth = 430;
  static const int crossAxisCount = 2;
  static const double spacing = 10;
  static const double horizontalPadding = 32;

  static const double homeImageRatio = 0.85;
  static const double catalogImageRatio = 0.72;
  static const double homeContentHeight = 108;
  static const double catalogContentHeight = 140;

  /// Legacy alias used by [DamosProductGridCard].
  static const double contentHeight = homeContentHeight;

  static double _effectiveWidth(BuildContext context) {
    return math.min(MediaQuery.sizeOf(context).width, maxLayoutWidth);
  }

  static double itemWidth(BuildContext context) {
    final width = _effectiveWidth(context);
    final totalSpacing = spacing * (crossAxisCount - 1);
    return (width - horizontalPadding - totalSpacing) / crossAxisCount;
  }

  static double homeImageHeight(BuildContext context) {
    return itemWidth(context) * homeImageRatio;
  }

  static double catalogImageHeight(BuildContext context) {
    return itemWidth(context) * catalogImageRatio;
  }

  static double imageHeight(BuildContext context) => homeImageHeight(context);

  static double homeCardHeight(BuildContext context) {
    return homeImageHeight(context) + homeContentHeight;
  }

  static double catalogCardHeight(BuildContext context) {
    return catalogImageHeight(context) + catalogContentHeight;
  }

  static double cardHeight(BuildContext context) => homeCardHeight(context);

  static SliverGridDelegate homeGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: homeCardHeight(context),
    );
  }

  static SliverGridDelegate catalogGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: catalogCardHeight(context),
    );
  }

  static SliverGridDelegate responsiveDelegate(
    BuildContext context, {
    bool catalog = false,
  }) {
    return catalog ? catalogGridDelegate(context) : homeGridDelegate(context);
  }

  static SliverGridDelegate responsiveSliverDelegate(
    BuildContext context, {
    bool catalog = false,
  }) {
    return responsiveDelegate(context, catalog: catalog);
  }

  /// Tombol Beli di dalam kartu grid — hindari minimumSize lebar infinite dari tema global.
  static ButtonStyle buyButtonStyle({
    required Color primary,
    required Color disabledBg,
    double height = 36,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: disabledBg,
      disabledForegroundColor: Colors.white70,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: Size(0, height),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
