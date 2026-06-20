import 'package:flutter/material.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color timeLabel = Color(0xFF1A3C8F);
}

class NotificationBanner extends StatelessWidget {
  final String title;
  final String message;
  final String timeLabelText;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.timeLabelText = 'Sekarang',
    this.onClose,
    this.onTap,
  });

  static OverlayEntry? _overlayEntry;

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String timeLabelText = 'Sekarang',
    VoidCallback? onTap,
    Duration autoHide = const Duration(seconds: 6),
  }) {
    hide();

    final overlay = Overlay.of(context, rootOverlay: true);
    final topPadding = MediaQuery.paddingOf(context).top;

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _Ds.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, size: 22, color: _Ds.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Ds.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Ds.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabelText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _Ds.timeLabel,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onClose ?? hide,
                  child: const Icon(Icons.close, size: 16, color: _Ds.hint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
