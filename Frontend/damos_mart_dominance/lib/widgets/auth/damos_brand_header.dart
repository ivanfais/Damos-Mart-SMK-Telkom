import 'package:flutter/material.dart';
import '../../theme/damos_dominance_colors.dart';
import 'damos_logo.dart';

class DamosBrandHeader extends StatelessWidget {
  final String subtitle;
  final bool onPrimaryBackground;

  const DamosBrandHeader({
    super.key,
    this.subtitle = 'Koperasi Siswa SMK Telkom Jakarta',
    this.onPrimaryBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        onPrimaryBackground ? DamosDominanceColors.textOnPrimary : DamosDominanceColors.textPrimary;
    final subtitleColor = onPrimaryBackground
        ? DamosDominanceColors.textOnPrimary.withValues(alpha: 0.92)
        : DamosDominanceColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DamosLogo(
          width: 160,
          height: 115,
          errorIconColor: DamosDominanceColors.textOnPrimary,
        ),
        const SizedBox(height: 12),
        Text(
          'DAMOS MART',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}
