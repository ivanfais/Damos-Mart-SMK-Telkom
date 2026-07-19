import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../core/utils/variant_asset_image.dart';

/// Ikon menu Tata Cara Penggunaan — asset [AppConstants.imageUsageGuideMenu].
class UsageGuideMenuIcon extends StatelessWidget {
  const UsageGuideMenuIcon({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: VariantAssetImage.asset(
        AppConstants.imageUsageGuideMenu,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.menu_book_outlined,
          size: size,
          color: const Color(0xFF1B8C2E),
        ),
      ),
    );
  }
}
