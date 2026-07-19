import 'package:flutter/widgets.dart';

/// Loads assets bundled in the [variant_steadiness] package (unified app host).
class VariantAssetImage {
  VariantAssetImage._();

  static const String package = 'variant_steadiness';

  static Image asset(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    return Image.asset(
      path,
      package: package,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }
}
