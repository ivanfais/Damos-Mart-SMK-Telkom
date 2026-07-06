import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transisi halaman Damos Mart — halus, konsisten, tidak terburu-buru.
///
/// - Durasi 300 ms (rentang 250–350 ms)
/// - Kurva [Curves.easeInOut]
/// - Geser horizontal ringan + fade (tanpa bounce/zoom berlebihan)
class DamosPageTransitions {
  DamosPageTransitions._();

  static const Duration duration = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeInOut;

  /// Geser masuk dari kanan — cukup terasa, tidak seagresif full-screen slide.
  static const Offset _pushSlideBegin = Offset(0.07, 0.0);

  /// Push / detail / checkout / auth setelah shell.
  static CustomTransitionPage<void> page({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.uri.toString(),
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: _buildPushTransition,
    );
  }

  /// Tab bottom nav & halaman dalam shell — fade lembut tanpa geser
  /// (menghindari glitch paint ListView di Flutter Web).
  static CustomTransitionPage<void> shellPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.uri.toString(),
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: _buildFadeTransition,
    );
  }

  static Widget _buildPushTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: curve);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: curve);

    final slideIn = Tween<Offset>(
      begin: _pushSlideBegin,
      end: Offset.zero,
    ).animate(enter);

    final fadeIn = Tween<double>(begin: 0.92, end: 1.0).animate(enter);

    // Halaman di bawah sedikit bergeser & redup saat halaman baru masuk.
    final slideUnder = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.03, 0.0),
    ).animate(exit);

    final fadeUnder = Tween<double>(begin: 1.0, end: 0.96).animate(exit);

    return SlideTransition(
      position: slideUnder,
      child: FadeTransition(
        opacity: fadeUnder,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _buildFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: curve);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.94, end: 1.0).animate(enter),
      child: child,
    );
  }
}
