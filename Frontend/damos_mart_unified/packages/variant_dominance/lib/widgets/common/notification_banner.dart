import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../theme/damos_dominance_colors.dart';

class NotificationBanner extends StatelessWidget {
  final String title;
  final String message;
  final String timeLabelText;
  final String? tapActionLabel;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.timeLabelText = 'Sekarang',
    this.tapActionLabel,
    this.onClose,
    this.onTap,
  });

  static OverlayEntry? _overlayEntry;

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void show({
    BuildContext? context,
    required String title,
    required String message,
    String timeLabelText = 'Sekarang',
    String? tapActionLabel,
    VoidCallback? onTap,
    Duration autoHide = const Duration(seconds: 8),
  }) {
    hide();

    final overlay = AppRouter.rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final ctx = context ?? AppRouter.rootNavigatorKey.currentContext;
    final topPadding = ctx != null ? MediaQuery.paddingOf(ctx).top : 0.0;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: topPadding + 8,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: NotificationBanner(
              title: title,
              message: message,
              timeLabelText: timeLabelText,
              tapActionLabel: tapActionLabel,
              onTap: onTap,
              onClose: hide,
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    if (autoHide != Duration.zero) {
      Future.delayed(autoHide, () {
        if (_overlayEntry != null) hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DamosDominanceColors.fieldBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 24,
                color: DamosDominanceColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DamosDominanceColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeLabelText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: DamosDominanceColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onClose ?? hide,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: DamosDominanceColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DamosDominanceColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (onTap != null && tapActionLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      tapActionLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DamosDominanceColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
