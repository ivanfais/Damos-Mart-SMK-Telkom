import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/app_constants.dart';
import '../../core/disc/disc_app_config.dart';
import '../../widgets/common/steadiness_app_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFD3D3D3);
  static const Color _titleColor = Color(0xFF1A1A1A);
  static const Color _subtitleColor = Color(0xFF4B5563);
  static const Color _versionColor = Color(0xFF6B7280);
  static const Color _dividerColor = Color(0xFFBDBDBD);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeIn);
    _entranceController.forward();

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated) {
          _navigateAfterDelay(state);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              const SteadinessHeaderTricolorStripe(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Image.asset(
                        AppConstants.imageLogo,
                        width: 200,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_outlined,
                          size: 80,
                          color: SteadinessHeaderColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Damos Mart',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Koperasi Sekolah SMK Telkom Jakarta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: _subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Versi ${DiscAppConfig.hostVariant.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SteadinessHeaderColors.primary,
                        ),
                      ),
                      const Spacer(flex: 4),
                      const Divider(
                        color: _dividerColor,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Versi ${AppConstants.appVersion}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _versionColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SteadinessHeaderTricolorStripe(),
            ],
          ),
        ),
      ),
    );
  }
}
