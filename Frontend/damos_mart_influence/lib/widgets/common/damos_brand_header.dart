import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/utils/damos_system_ui.dart';
import '../../config/app_constants.dart';
import 'user_avatar.dart';

/// Baris logo + judul + profil (tanpa wrapper hijau).
class DamosBrandHeaderRow extends StatelessWidget {
  const DamosBrandHeaderRow({
    super.key,
    this.showProfileAvatar = true,
    this.showBackButton = false,
    this.showTagline = true,
    this.onBack,
  });

  final bool showProfileAvatar;
  final bool showBackButton;
  final bool showTagline;
  final VoidCallback? onBack;

  static const Color primary = Color(0xFF1B8C2E);
  static const double profileAvatarRadius = 24;
  static const double profileBorderWidth = 2;
  static const double headerIconOuterSize =
      (profileAvatarRadius + profileBorderWidth) * 2;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/queue');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBackButton)
          IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        SizedBox(
          width: headerIconOuterSize,
          height: headerIconOuterSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.asset(
              AppConstants.imageLogo,
              width: headerIconOuterSize,
              height: headerIconOuterSize,
              errorBuilder: (_, __, ___) => Icon(
                Icons.storefront,
                color: Colors.white,
                size: headerIconOuterSize * 0.55,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: showTagline
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Damos Mart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Melayani Kebutuhan, Mendukung Pendidikan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Damos Mart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
        ),
        if (showProfileAvatar) const _ProfileAvatarButton(),
      ],
    );
  }
}

/// Green brand header tanpa search bar (Antrean, dll).
class DamosBrandHeader extends StatelessWidget {
  const DamosBrandHeader({
    super.key,
    this.showProfileAvatar = true,
    this.showBackButton = false,
    this.showTagline = true,
    this.onBack,
  });

  final bool showProfileAvatar;
  final bool showBackButton;
  final bool showTagline;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: DamosBrandHeaderRow.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(12, topPadding + 12, 20, 20),
        child: DamosBrandHeaderRow(
          showProfileAvatar: showProfileAvatar,
          showBackButton: showBackButton,
          showTagline: showTagline,
          onBack: onBack,
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String? avatarUrl;
          if (state is Authenticated) {
            avatarUrl = state.user.avatarUrl;
          }

          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: DamosBrandHeaderRow.profileBorderWidth,
              ),
            ),
            child: UserAvatar(
              avatarUrl: avatarUrl,
              radius: DamosBrandHeaderRow.profileAvatarRadius,
              backgroundColor: Colors.white,
              iconColor: DamosBrandHeaderRow.primary,
              iconSize: 24,
            ),
          );
        },
      ),
    );
  }
}
