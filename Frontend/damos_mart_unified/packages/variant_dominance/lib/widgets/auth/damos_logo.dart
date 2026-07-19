import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class DamosLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color? errorIconColor;

  const DamosLogo({
    super.key,
    this.width = 140,
    this.height = 100,
    this.errorIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        AppConstants.imageLogoKoperasi,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.storefront_outlined,
          size: height * 0.72,
          color: errorIconColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
