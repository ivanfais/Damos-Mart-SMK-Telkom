import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFFCF8F8);

  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

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
    _controller.dispose();
    super.dispose();
  }

  void _navigateAfterDelay(AuthState state) async {
    if (_isNavigated) return;
    _isNavigated = true;
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    if (state is Authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated) {
          _navigateAfterDelay(state);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 90,
                  child: Image.asset(
                    AppConstants.imageLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _DamosLogo(size: 100),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DAMOS MART',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'SMK Telkom Jakarta',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DamosLogo extends StatelessWidget {
  final double size;
  const _DamosLogo({this.size = 100});

  static const Color _green  = Color(0xFF1B8C2E);
  static const Color _yellow = Color(0xFFF5C518);
  static const Color _red    = Color(0xFFD42427);
  static const Color _blue   = Color(0xFF1A3C8F);

  @override
  Widget build(BuildContext context) {
    final w = size * 1.4;
    final h = size;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _oval(w, h, _green),
          _oval(w * 0.91, h * 0.89, _yellow),
          _oval(w * 0.82, h * 0.76, _red),
          _oval(w * 0.70, h * 0.60, Colors.white),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('OMI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _blue, letterSpacing: 2, height: 1.1)),
              Text('DAMOS MART',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _blue, letterSpacing: 1, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oval(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
        ),
      );
}
