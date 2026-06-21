import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive 2-column product grid sized for mobile (~430px max).
class ProductGridLayout {
  static const double _maxLayoutWidth = 430;
  static const int _crossAxisCount = 2;
  static const double _spacing = 10;
  static const double _horizontalPadding = 32;
  static const double _imageRatio = 0.72;
  static const double contentHeight = 110;

  static double _effectiveWidth(BuildContext context) {
    return math.min(MediaQuery.sizeOf(context).width, _maxLayoutWidth);
  }

  static double itemWidth(BuildContext context) {
    final width = _effectiveWidth(context);
    final totalSpacing = _spacing * (_crossAxisCount - 1);
    return (width - _horizontalPadding - totalSpacing) / _crossAxisCount;
  }

  static double imageHeight(BuildContext context) {
    return itemWidth(context) * _imageRatio;
  }

  static double cardHeight(BuildContext context) {
    return imageHeight(context) + contentHeight;
  }

  static SliverGridDelegate responsiveDelegate(
    BuildContext context, {
    double horizontalPadding = _horizontalPadding,
  }) {
    final width = _effectiveWidth(context);
    const crossAxisCount = _crossAxisCount;
    const spacing = _spacing;
    final totalSpacing = spacing * (crossAxisCount - 1);
    final cellWidth = (width - horizontalPadding - totalSpacing) / crossAxisCount;
    final mainAxisExtent = cellWidth * _imageRatio + contentHeight;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: mainAxisExtent,
    );
  }

  static SliverGridDelegate responsiveSliverDelegate(
    BuildContext context, {
    double horizontalPadding = _horizontalPadding,
  }) {
    return responsiveDelegate(context, horizontalPadding: horizontalPadding);
  }
}
