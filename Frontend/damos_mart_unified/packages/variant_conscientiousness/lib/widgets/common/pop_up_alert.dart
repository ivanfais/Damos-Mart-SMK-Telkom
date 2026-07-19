import 'package:flutter/material.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color red = Color(0xFFD42427);
}

class PopUpAlert extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Kept for backward compatibility; visual style is unified for all alerts.
  final bool isError;
  final bool showActions;

  const PopUpAlert({
    super.key,
    required this.title,
    required this.description,
    this.confirmText = 'OK',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isError = true,
    this.showActions = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    String confirmText = 'OK',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isError = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: cancelText == null,
      builder: (context) => PopUpAlert(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isError: isError,
      ),
    );
  }

  static Future<void> showIncompleteData(
    BuildContext context, {
    String? title,
    String? description,
  }) {
    return show(
      context: context,
      title: title ?? 'Data Belum Lengkap',
      description: description ?? 'Silakan isi semua kolom yang tersedia sebelum melanjutkan.',
      confirmText: 'OK',
      isError: true,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String description,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: title,
      description: description,
      confirmText: confirmText,
      onConfirm: onConfirm,
      isError: false,
    );
  }

  static Future<void> showNotice({
    required BuildContext context,
    required String title,
    required String description,
    bool isError = false,
    Duration autoDismiss = const Duration(milliseconds: 1800),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(autoDismiss, () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return PopUpAlert(
          title: title,
          description: description,
          isError: isError,
          showActions: false,
        );
      },
    );
  }

  static void showAddedToCart({
    required BuildContext context,
    required String productName,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CartToast(
        message: productName,
        onRemove: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final iconData = isError ? Icons.error_outline : Icons.check_circle_outline;

    final iconColor = isError ? _Ds.red : _Ds.primary;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _Ds.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _Ds.textSecondary,
                height: 1.5,
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (cancelText != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Ds.textPrimary,
                      side: const BorderSide(color: _Ds.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      cancelText!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CartToast extends StatefulWidget {
  final String message;
  final VoidCallback onRemove;
  const _CartToast({required this.message, required this.onRemove});

  @override
  State<_CartToast> createState() => _CartToastState();
}

class _CartToastState extends State<_CartToast>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF018D1A);

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onRemove());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    return Stack(
      children: [
        // Semi-transparent grey overlay
        FadeTransition(
          opacity: _fade,
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        Positioned(
      top: top,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle,
                      color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ],
    );
  }
}
