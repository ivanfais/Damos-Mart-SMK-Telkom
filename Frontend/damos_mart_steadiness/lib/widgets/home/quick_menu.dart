import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class QuickMenu extends StatelessWidget {
  final void Function(int index) onTapItem;

  const QuickMenu({super.key, required this.onTapItem});

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'label': 'Katalog',
      'icon': Icons.grid_view_rounded,
      'emoji': '📦',
    },
    {
      'label': 'Antrean',
      'icon': Icons.stars_rounded,
      'emoji': '🎯',
    },
    {
      'label': 'Informasi',
      'icon': Icons.info_outline_rounded,
      'emoji': 'ℹ️',
    },
    {
      'label': 'Riwayat',
      'icon': Icons.history_rounded,
      'emoji': '📜',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_menuItems.length, (index) {
        final item = _menuItems[index];
        return GestureDetector(
          onTap: () => onTapItem(index),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item['label']} ${item['emoji']}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
