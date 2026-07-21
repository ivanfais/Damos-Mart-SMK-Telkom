import 'package:flutter/material.dart';
import '../../theme/damos_dominance_colors.dart';

/// Read-only search bar — tap opens the dedicated search screen.
class DamosSearchBarTrigger extends StatelessWidget {
  const DamosSearchBarTrigger({
    super.key,
    required this.onTap,
    this.hintText = 'Cari produk...',
    this.height = 44,
    this.fillColor = Colors.white,
    this.borderRadius = 8,
    this.iconSize = 20,
    this.fontSize = 14,
  });

  final VoidCallback onTap;
  final String hintText;
  final double height;
  final Color fillColor;
  final double borderRadius;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: DamosDominanceColors.textHint,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DamosDominanceColors.textHint,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
