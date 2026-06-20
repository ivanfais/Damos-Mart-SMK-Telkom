import 'package:flutter/material.dart';

class AppDimensions {
  // Border Radius — rounded tinggi untuk kesan friendly (Influence signature)
  static const double radiusSmall   = 8.0;
  static const double radiusMedium  = 12.0;
  static const double radiusLarge   = 16.0;
  static const double radiusXLarge  = 24.0;
  static const double radiusFull    = 50.0; // pill shape button

  // Padding & Margin
  static const double paddingXSmall = 4.0;
  static const double paddingSmall  = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge  = 24.0;
  static const double paddingXLarge = 32.0;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20.0);

  // Card
  static const double cardElevation   = 2.0;
  static const double cardRadius      = 16.0;

  // Button
  static const double buttonHeight    = 52.0;
  static const double buttonRadius    = 50.0; // pill shape
  static const double buttonIconSize  = 20.0;

  // Input field
  static const double inputHeight     = 52.0;
  static const double inputRadius     = 12.0;

  // Bottom nav
  static const double bottomNavHeight = 70.0;

  // Product card
  static const double productCardImageHeight = 120.0;

  // App bar
  static const double appBarHeight = 60.0;

  // Banner
  static const double bannerHeight = 160.0;

  // Avatar
  static const double avatarSmall  = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge  = 80.0;
}

class AppAnimations {
  // Transisi halaman: slide + fade (smooth)
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // Micro-interaction: bounce pada tombol
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration buttonBounce = Duration(milliseconds: 300);

  // Fade in untuk konten
  static const Duration fadeIn = Duration(milliseconds: 400);
  static const Curve fadeInCurve = Curves.easeIn;

  // Scale untuk card hover/tap
  static const Duration cardScale = Duration(milliseconds: 200);
  static const double cardScaleValue = 0.97; // scale down sedikit saat tap

  // Shimmer loading
  static const Duration shimmer = Duration(milliseconds: 1500);

  // Snackbar/toast
  static const Duration snackbar = Duration(seconds: 3);

  // Stagger list animation
  static const Duration staggerDelay = Duration(milliseconds: 50);
}
