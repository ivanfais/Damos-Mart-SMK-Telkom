import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared page transition: slide in from the east (right) with ease-in curve.
class DamosPageTransitions {
  DamosPageTransitions._();

  static const Duration duration = Duration(milliseconds: 380);
  static const Curve enterCurve = Curves.easeInCubic;
  static const Curve exitCurve = Curves.easeOutCubic;

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
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final enterAnimation = CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(enterAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(enterAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Tab/shell screens: no slide animation (avoids Flutter Web list paint bugs).
  static NoTransitionPage<void> instantPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.uri.toString(),
      child: child,
    );
  }
}
