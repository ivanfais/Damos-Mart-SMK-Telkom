import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/storage/prefs_storage.dart';
import '../../data/models/user_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/profile/damos_logout_confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _discPickerSwitch = false;

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await DamosLogoutConfirmDialog.show(context);
    if (!confirmed || !context.mounted) return;

    context.read<AuthBloc>().add(LoggedOut());
  }


  Future<void> _onDiscPickerSwitchChanged(bool value) async {
    setState(() => _discPickerSwitch = value);
    if (!value) return;

    await context.push('/profile/disc-theme');
    if (!mounted) return;
    setState(() => _discPickerSwitch = false);
  }

  String _activeDiscLabel() {
    final variant = PrefsStorage.instance.getSelectedDiscVariant();
    return variant?.label ?? 'Dominance';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is Unauthenticated &&
          (previous is Authenticated || previous is AuthLoading),
      listener: (context, state) {
        context.go('/login');
      },
      child: Scaffold(
        backgroundColor: DamosDominanceColors.screenBackground,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! Authenticated) {
              return const Center(
                child: CircularProgressIndicator(
                  color: DamosDominanceColors.primary,
                ),
              );
            }

            final user = state.user;

            return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DamosPageHeader(
                  title: 'PENGATURAN PROFIL',
                  showBackButton: false,
                  titleWidget: Center(
                    child: Text(
                      'PENGATURAN PROFIL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UserSummaryCard(user: user),
                      const SizedBox(height: 24),
                      const _SectionLabel('Account'),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        children: [
                          _ProfileMenuRow(
                            icon: Icons.person_outline,
                            title: 'Edit Profil',
                            subtitle: 'Ganti Foto Profil, Nomor Telepon, E-mail',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          const _SettingsDivider(),
                          _ProfileMenuRow(
                            icon: Icons.lock_outline,
                            title: 'Ubah Password',
                            subtitle: 'Perbarui Keamanan akunmu',
                            onTap: () => context.push('/profile/change-password'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('General'),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        children: [
                          _ProfileMenuRow(
                            icon: Icons.help_outline,
                            iconBackground: const Color(0xFFE8F0FE),
                            iconColor: const Color(0xFF1A73E8),
                            titleColor: const Color(0xFF1A73E8),
                            title: 'Bantuan & Komplain',
                            subtitle: 'Sampaikan Keluhan anda',
                            onTap: () => context.push('/complaints'),
                          ),
                          const _SettingsDivider(),
                          _ProfileMenuRow(
                            icon: Icons.favorite,
                            iconBackground: DamosDominanceColors.primary.withValues(alpha: 0.12),
                            iconColor: DamosDominanceColors.primary,
                            titleColor: DamosDominanceColors.primary,
                            title: 'Favorite Saya',
                            subtitle: 'Daftar barang kesukaan Anda',
                            onTap: () => context.push('/favorites'),
                          ),
                          const _SettingsDivider(),
                          _ProfileMenuRow(
                            icon: Icons.palette_outlined,
                            iconBackground: DamosDominanceColors.primary.withValues(alpha: 0.12),
                            iconColor: DamosDominanceColors.primary,
                            titleColor: DamosDominanceColors.primary,
                            title: 'Gaya Aplikasi DISC',
                            subtitle: 'Aktif: ${_activeDiscLabel()} · Ketuk switch untuk ganti',
                            trailing: Switch.adaptive(
                              value: _discPickerSwitch,
                              thumbColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return DamosDominanceColors.primary;
                                }
                                return null;
                              }),
                              trackColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return DamosDominanceColors.primary.withValues(alpha: 0.35);
                                }
                                return null;
                              }),
                              onChanged: _onDiscPickerSwitchChanged,
                            ),
                          ),
                          const _SettingsDivider(),
                          _ProfileMenuRow(
                            icon: Icons.logout,
                            iconBackground: DamosDominanceColors.error.withValues(alpha: 0.12),
                            iconColor: DamosDominanceColors.error,
                            titleColor: DamosDominanceColors.error,
                            title: 'Log Out',
                            subtitle: 'Keluar dari aplikasi',
                            onTap: () => _showLogoutConfirmation(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: user.avatarUrl,
            radius: 32,
            iconSize: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DamosDominanceColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: DamosDominanceColors.textSecondary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: DamosDominanceColors.fieldBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.titleColor,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBackground;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? DamosDominanceColors.textPrimary;
    final resolvedTitleColor = titleColor ?? DamosDominanceColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground ?? Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: resolvedIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: resolvedTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DamosDominanceColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right,
                  color: DamosDominanceColors.textHint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
