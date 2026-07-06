import 'package:flutter/material.dart';

class AppDimensions {
  // Border Radius — lebih tajam/formal untuk C-type
  static const double radiusXSmall  = 4.0;
  static const double radiusSmall   = 6.0;
  static const double radiusMedium  = 8.0;
  static const double radiusLarge   = 10.0;
  static const double radiusXLarge  = 12.0;
  static const double radiusFull    = 8.0; // tidak pill, rectangular rounded

  // Padding & Margin
  static const double paddingXSmall = 4.0;
  static const double paddingSmall  = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge  = 24.0;
  static const double paddingXLarge = 32.0;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);

  // Card
  static const double cardElevation = 0.0;
  static const double cardRadius    = 8.0;

  // Button
  static const double buttonHeight  = 52.0;
  static const double buttonRadius  = 8.0;
  static const double buttonIconSize = 20.0;

  // Input field
  static const double inputHeight   = 52.0;
  static const double inputRadius   = 8.0;

  // Bottom nav
  static const double bottomNavHeight = 70.0;

  // Product card
  static const double productCardImageSize = 72.0;

  // App bar
  static const double appBarHeight  = 60.0;

  // Avatar
  static const double avatarSmall   = 32.0;
  static const double avatarMedium  = 48.0;
  static const double avatarLarge   = 80.0;

  // Quick menu icon box
  static const double quickMenuBoxSize = 64.0;
  static const double quickMenuIconSize = 28.0;
}

class AppAnimations {
  // Transisi halaman: clean, minimal
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // Button — tidak ada bounce, cukup fade
  static const Duration buttonPress = Duration(milliseconds: 100);

  // Fade in
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Curve fadeInCurve = Curves.easeIn;

  // Card tap — subtle
  static const Duration cardScale = Duration(milliseconds: 150);
  static const double cardScaleValue = 0.99;

  // Shimmer
  static const Duration shimmer = Duration(milliseconds: 1500);

  // Snackbar
  static const Duration snackbar = Duration(seconds: 3);

  // Stagger
  static const Duration staggerDelay = Duration(milliseconds: 30);
}
