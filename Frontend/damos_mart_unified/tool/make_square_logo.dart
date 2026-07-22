import 'dart:io';
import 'package:image/image.dart' as img;

/// Creates a square version of logo_damos_mart.png without distorting it.
/// The original logo is centered on a square canvas so launcher icons
/// (which are square) keep the logo's exact proportions.
void main() {
  const srcPath = 'assets/images/logo_damos_mart.png';
  const outPath = 'assets/images/logo_damos_mart_square.png';

  final bytes = File(srcPath).readAsBytesSync();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode $srcPath');
    exit(1);
  }

  // Sample the corner pixel to detect background (transparent vs solid).
  final corner = src.getPixel(0, 0);
  final bgAlpha = corner.a;
  final isTransparentBg = bgAlpha < 8;

  final side = src.width > src.height ? src.width : src.height;
  // No padding: logo fills the square edge-to-edge for maximum size.
  final canvasSide = side;

  final canvas = img.Image(
    width: canvasSide,
    height: canvasSide,
    numChannels: 4,
  );

  if (isTransparentBg) {
    // Fully transparent padding.
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  } else {
    // Match the logo's own background color so padding blends in.
    img.fill(
      canvas,
      color: img.ColorRgba8(
        corner.r.toInt(),
        corner.g.toInt(),
        corner.b.toInt(),
        255,
      ),
    );
  }

  final dx = ((canvasSide - src.width) / 2).round();
  final dy = ((canvasSide - src.height) / 2).round();
  img.compositeImage(canvas, src, dstX: dx, dstY: dy);

  File(outPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln(
    'Wrote $outPath (${canvas.width}x${canvas.height}), '
    'bg=${isTransparentBg ? "transparent" : "solid ${corner.r.toInt()},${corner.g.toInt()},${corner.b.toInt()}"}',
  );
}
