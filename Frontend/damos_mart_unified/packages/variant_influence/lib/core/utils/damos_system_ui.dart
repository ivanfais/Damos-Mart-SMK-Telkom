import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central status bar / system UI styling for the app.
class DamosSystemUi {
  DamosSystemUi._();

  static const Color primary = Color(0xFF1B8C2E);

  /// Green header screens — white status bar icons.
  static const SystemUiOverlayStyle greenHeader = SystemUiOverlayStyle(
    statusBarColor: primary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Light screens (login, splash) — dark status bar icons.
  static const SystemUiOverlayStyle lightHeader = SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static void apply(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Only splash & login use a white top area with dark icons.
  /// All other routes use green header styling (white icons).
  static SystemUiOverlayStyle forRoute(String location) {
    if (location == '/disc-picker') {
      return lightHeader;
    }
    if (location == '/' || location.startsWith('/?')) {
      return lightHeader;
    }
    if (location == '/login' || location.startsWith('/login?')) {
      return lightHeader;
    }
    return greenHeader;
  }
}
