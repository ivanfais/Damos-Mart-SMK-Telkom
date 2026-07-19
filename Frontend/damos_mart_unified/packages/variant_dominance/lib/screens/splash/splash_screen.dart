import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/app_constants.dart';
import '../../core/disc/disc_app_config.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/auth/damos_powered_by_footer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

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
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay(AuthState state) async {
    if (_isNavigated) return;
    _isNavigated = true;

    await Future.delayed(const Duration(milliseconds: 2500));
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
        backgroundColor: DamosDominanceColors.primary,
        body: ColoredBox(
          color: DamosDominanceColors.primary,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    SizedBox(
                      width: 180,
                      height: 130,
                      child: Image.asset(
                        AppConstants.imageLogoKoperasi,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.storefront_outlined,
                          size: 94,
                          color: DamosDominanceColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DAMOS MART',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: DamosDominanceColors.textOnPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.schoolName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: DamosDominanceColors.textOnPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Versi ${DiscAppConfig.hostVariant.label}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DamosDominanceColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(flex: 4),
                    const DamosPoweredByFooter(
                      textColor: DamosDominanceColors.textOnPrimary,
                    ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
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
