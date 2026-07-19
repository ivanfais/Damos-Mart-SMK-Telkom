import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables mouse/touch horizontal drag on Flutter web and hides scrollbars.
class DamosHorizontalScrollBehavior extends MaterialScrollBehavior {
  const DamosHorizontalScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
