import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../theme/damos_dominance_colors.dart';

/// Floating success toast aligned to top-right (Dominance profile flows).
class DamosSuccessBanner extends StatelessWidget {
  const DamosSuccessBanner({
    super.key,
    required this.title,
    required this.message,
    this.topOffset = 72,
  });

  final String title;
  final String message;
  final double topOffset;

  static OverlayEntry? _overlayEntry;

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void show({
    BuildContext? context,
    required String title,
    required String message,
    double topOffset = 72,
    Duration autoHide = const Duration(seconds: 3),
  }) {
    hide();

    final ctx = context ?? AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) return;

    final overlay = Overlay.of(ctx, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return DamosSuccessBanner(
          title: title,
          message: message,
          topOffset: topOffset,
        );
      },
    );

    overlay.insert(_overlayEntry!);

    if (autoHide != Duration.zero) {
      Future.delayed(autoHide, hide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + topOffset,
      right: 20,
      left: 20,
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DamosDominanceColors.primary.withValues(alpha: 0.35),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DamosDominanceColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
