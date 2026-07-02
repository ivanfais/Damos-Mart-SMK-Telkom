import 'package:flutter/material.dart';
import '../../core/utils/damos_horizontal_scroll_behavior.dart';
import '../../theme/damos_dominance_colors.dart';

class DamosCatalogCategoryChips extends StatelessWidget {
  static const List<String> defaultChipLabels = [
    'Semua',
    'Makanan',
    'Minuman',
    'Atribut Sekolah',
    'Alat Tulis',
  ];

  final List<String>? chipLabels;
  final String selectedLabel;
  final ValueChanged<String> onSelected;
  final bool favoritesStyle;

  const DamosCatalogCategoryChips({
    super.key,
    this.chipLabels,
    required this.selectedLabel,
    required this.onSelected,
    this.favoritesStyle = false,
  });

  List<String> get _labels => chipLabels ?? defaultChipLabels;

  EdgeInsets get _chipPadding {
    if (favoritesStyle) {
      return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: favoritesStyle ? 34 : 40,
      child: ScrollConfiguration(
        behavior: const DamosHorizontalScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final label = _labels[index];
            final isSelected = selectedLabel == label;

            return GestureDetector(
              onTap: () => onSelected(label),
              child: Container(
                padding: _chipPadding,
                decoration: BoxDecoration(
                  color: isSelected
                      ? DamosDominanceColors.primary
                      : (favoritesStyle
                          ? DamosDominanceColors.fieldFill
                          : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected || favoritesStyle
                      ? null
                      : Border.all(color: DamosDominanceColors.fieldBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? DamosDominanceColors.textOnPrimary
                        : (favoritesStyle
                            ? DamosDominanceColors.textSecondary
                            : DamosDominanceColors.textPrimary
                                .withValues(alpha: 0.5)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
