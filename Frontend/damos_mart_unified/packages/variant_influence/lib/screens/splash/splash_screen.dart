import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/storage/prefs_storage.dart';
import '../../config/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFF2F2F2);
  static const Color _spinnerColor = Color(0xFF3CB371);
  static const Color _titleColor = Color(0xFF1A1A1A);
  static const Color _taglineColor = Color(0xFF6B7280);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _spinController;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeIn);
    _entranceController.forward();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AuthBloc>().state;
      if (state is Authenticated || state is Unauthenticated) {
        _navigateAfterDelay(state);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _navigateAfterDelay(AuthState state) async {
    if (_isNavigated) return;
    _isNavigated = true;

    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    if (state is Authenticated) {
      context.go('/home');
    } else if (state is Unauthenticated) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final discVariant = PrefsStorage.instance.getSelectedDiscVariant();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated) {
          _navigateAfterDelay(state);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    SizedBox(
                      width: 180,
                      height: 130,
                      child: Image.asset(
                        AppConstants.imageLogo,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => const _DamosLogo(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'DAMOS MART',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Melayani Kebutuhan,\nMendukung Pendidikan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: _taglineColor,
                      ),
                    ),
                    if (discVariant != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Versi ${discVariant.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _spinnerColor,
                        ),
                      ),
                    ],

                    const Spacer(flex: 2),

                    SizedBox(
                      width: 60,
                      height: 60,
                      child: RotationTransition(
                        turns: _spinController,
                        child: CustomPaint(
                          size: const Size(60, 60),
                          painter: _SpinnerPainter(color: _spinnerColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'LOADING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _spinnerColor,
                        letterSpacing: 3,
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The concentric-ellipse "OMI / DAMOS MART" brand logo, recreated with widgets.
class _DamosLogo extends StatelessWidget {
  const _DamosLogo();

  static const Color _green = Color(0xFF1B8C2E);
  static const Color _yellow = Color(0xFFF5C518);
  static const Color _red = Color(0xFFD42427);
  static const Color _blue = Color(0xFF1A3C8F);

  Widget _ellipse(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ellipse(176, 126, _green),
          _ellipse(160, 112, _yellow),
          _ellipse(144, 96, _red),
          _ellipse(124, 76, Colors.white),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'OMI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'DAMOS MART',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                  letterSpacing: 1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws a rotating arc with a fading (gradient) stroke, mimicking the SVG spinner.
class _SpinnerPainter extends CustomPainter {
  final Color color;

  _SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3; // strokeWidth 5 → keep arc inside bounds
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      colors: [color.withOpacity(0.0), color],
      stops: const [0.0, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // 270° arc (three-quarter circle), leaving a 90° gap.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) => oldDelegate.color != color;
}
