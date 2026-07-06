import 'package:flutter/material.dart';

/// Riwayat Pesanan nav icon — outline when inactive, filled green + white lines when active.
class DamosHistoryNavIcon extends StatelessWidget {
  const DamosHistoryNavIcon({
    super.key,
    required this.color,
    this.size = 24,
    this.isSelected = false,
  });

  final Color color;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DamosHistoryNavIconPainter(
        color: color,
        isSelected: isSelected,
      ),
    );
  }
}

class _DamosHistoryNavIconPainter extends CustomPainter {
  _DamosHistoryNavIconPainter({
    required this.color,
    required this.isSelected,
  });

  final Color color;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final docRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.12,
        size.width * 0.56,
        size.height * 0.76,
      ),
      Radius.circular(size.width * 0.08),
    );

    if (isSelected) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(docRect, fillPaint);

      final linePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final lineLeft = size.width * 0.32;
      final lineRight = size.width * 0.68;
      for (final y in [0.38, 0.52, 0.66].map((v) => size.height * v)) {
        canvas.drawLine(Offset(lineLeft, y), Offset(lineRight, y), linePaint);
      }
      return;
    }

    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(docRect, outlinePaint);

    final lineLeft = size.width * 0.32;
    final lineRight = size.width * 0.68;
    for (final y in [0.38, 0.52, 0.66].map((v) => size.height * v)) {
      canvas.drawLine(Offset(lineLeft, y), Offset(lineRight, y), outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DamosHistoryNavIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSelected != isSelected;
  }
}
