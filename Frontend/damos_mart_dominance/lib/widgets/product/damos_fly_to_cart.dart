import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../theme/damos_dominance_colors.dart';

class DamosFlyToCart {
  DamosFlyToCart._();

  static Future<void> animate({
    required BuildContext context,
    required GlobalKey fromKey,
    required GlobalKey toKey,
    String? imageUrl,
    VoidCallback? onComplete,
  }) async {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      onComplete?.call();
      return;
    }

    final fromRender = fromKey.currentContext?.findRenderObject() as RenderBox?;
    final toRender = toKey.currentContext?.findRenderObject() as RenderBox?;
    if (fromRender == null || !fromRender.hasSize || toRender == null || !toRender.hasSize) {
      onComplete?.call();
      return;
    }

    final startTopLeft = fromRender.localToGlobal(Offset.zero);
    final startSize = fromRender.size;
    final startCenter = startTopLeft + Offset(startSize.width / 2, startSize.height / 2);

    final endTopLeft = toRender.localToGlobal(Offset.zero);
    final endSize = toRender.size;
    final endCenter = endTopLeft + Offset(endSize.width / 2, endSize.height / 2);

    late OverlayEntry entry;
    final completer = Completer<void>();

    entry = OverlayEntry(
      builder: (overlayContext) => _FlyToCartOverlay(
        startCenter: startCenter,
        endCenter: endCenter,
        imageUrl: imageUrl,
        onDone: () {
          if (entry.mounted) entry.remove();
          onComplete?.call();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    overlayState.insert(entry);
    return completer.future;
  }
}

class _FlyToCartOverlay extends StatefulWidget {
  final Offset startCenter;
  final Offset endCenter;
  final String? imageUrl;
  final VoidCallback onDone;

  const _FlyToCartOverlay({
    required this.startCenter,
    required this.endCenter,
    this.imageUrl,
    required this.onDone,
  });

  @override
  State<_FlyToCartOverlay> createState() => _FlyToCartOverlayState();
}

class _FlyToCartOverlayState extends State<_FlyToCartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _quadBezier(Offset start, Offset control, Offset end, double t) {
    final inverse = 1 - t;
    return start * (inverse * inverse) +
        control * (2 * inverse * t) +
        end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOutCubic.transform(_controller.value);
            final mid = Offset.lerp(widget.startCenter, widget.endCenter, 0.5)!;
            final control = mid + Offset(0, -(widget.startCenter.dy * 0.15 + 60));
            final position = _quadBezier(widget.startCenter, control, widget.endCenter, t);
            final size = lerpDouble(64, 18, t)!;
            final opacity = (1 - t * 0.25).clamp(0.0, 1.0);

            return Stack(
              children: [
                Positioned(
                  left: position.dx - size / 2,
                  top: position.dy - size / 2,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18 * opacity),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ApiConfig.imageUrl(widget.imageUrl!),
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: DamosDominanceColors.textSecondary,
      ),
    );
  }
}
