import 'package:flutter/material.dart';
import '../../theme/damos_dominance_colors.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String emoji;
  final VoidCallback? onActionButtonPressed;
  final String? actionButtonText;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.emoji,
    this.onActionButtonPressed,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: DamosDominanceColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (onActionButtonPressed != null && actionButtonText != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onActionButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DamosDominanceColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionButtonText!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
