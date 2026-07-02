import 'package:flutter/material.dart';
import '../../core/utils/damos_horizontal_scroll_behavior.dart';
import '../../theme/damos_dominance_colors.dart';

/// Category filter chips for Favorite Saya — matches design spec.
class DamosFavoritesCategoryChips extends StatelessWidget {
  const DamosFavoritesCategoryChips({
    super.key,
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
  });

  final List<String> labels;
  final String selectedLabel;
  final ValueChanged<String> onSelected;

  static const _chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);
  static const _chipGap = 16.0;
  static const _chipRadius = 8.0;
  static const _inactiveChipFill = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ScrollConfiguration(
        behavior: const DamosHorizontalScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: _chipGap),
          itemBuilder: (context, index) {
            final label = labels[index];
            final isSelected = selectedLabel == label;

            return GestureDetector(
              onTap: () => onSelected(label),
              child: Container(
                padding: _chipPadding,
                decoration: BoxDecoration(
                  color: isSelected
                      ? DamosDominanceColors.primary
                      : _inactiveChipFill,
                  borderRadius: BorderRadius.circular(_chipRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: isSelected
                        ? DamosDominanceColors.textOnPrimary
                        : DamosDominanceColors.textPrimary.withValues(alpha: 0.5),
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
