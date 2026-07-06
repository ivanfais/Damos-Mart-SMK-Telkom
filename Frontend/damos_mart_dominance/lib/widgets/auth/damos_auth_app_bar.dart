import 'package:flutter/material.dart';
import '../../theme/damos_dominance_colors.dart';

class DamosAuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DamosAuthAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DamosDominanceColors.primary,
      foregroundColor: DamosDominanceColors.textOnPrimary,
      iconTheme: const IconThemeData(color: DamosDominanceColors.textOnPrimary),
      actionsIconTheme: const IconThemeData(color: DamosDominanceColors.textOnPrimary),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DamosDominanceColors.textOnPrimary,
        ),
      ),
    );
  }
}
