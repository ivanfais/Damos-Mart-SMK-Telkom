import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../data/models/user_model.dart';
import '../../core/storage/prefs_storage.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color red = Color(0xFFD42427);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    PopUpAlert.show(
      context: context,
      title: 'Logout',
      description: 'Apakah Anda yakin ingin keluar dari akun?',
      confirmText: 'Logout',
      cancelText: 'Batal',
      onConfirm: () {
        context.read<AuthBloc>().add(LoggedOut());
        context.go('/login');
      },
    );
  }

  String _displayPhone(UserModel user) {
    if (user.phone != null && user.phone!.trim().isNotEmpty) {
      return user.phone!;
    }
    return '-';
  }

  Widget _buildAvatar(BuildContext context, UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        UserAvatar(
          avatarUrl: user.avatarUrl,
          radius: 52,
          iconSize: 48,
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _Ds.textPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: iconColor ?? _Ds.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? _Ds.textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: textColor ?? _Ds.textSecondary, size: 22),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DamosPageHeader(
                    title: 'Informasi Pengguna',
                    showBackButton: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Center(child: _buildAvatar(context, user)),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayPhone(user),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160),
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Ds.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AKTIVITAS & KEAMANAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _Ds.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuContainer([
                    _buildMenuTile(
                      icon: Icons.palette_outlined,
                      title: 'Gaya Aplikasi DISC',
                      onTap: () => context.push('/profile/disc-theme'),
                    ),
                    if (PrefsStorage.instance.getSelectedDiscVariant() != null) ...[
                      const Divider(height: 1, color: _Ds.borderLight),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(Icons.check_circle_outline, color: _Ds.primary, size: 22),
                        title: Text(
                          'Aktif: ${PrefsStorage.instance.getSelectedDiscVariant()!.label}',
                          style: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuContainer([
                    _buildMenuTile(
                      icon: Icons.favorite_border,
                      title: 'Favorit Produk',
                      onTap: () => context.push('/profile/favorites'),
                    ),
                    const Divider(height: 1, color: _Ds.borderLight),
                    _buildMenuTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Hubungi Admin',
                      onTap: () => context.push('/profile/chat'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuContainer([
                    _buildMenuTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: _Ds.red,
                      textColor: _Ds.red,
                      onTap: () => _showLogoutConfirmation(context),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  const Text(
                    'Damos Mart',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SMK Telkom Jakarta',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Memuat data profil...'));
        },
      ),
    );
  }
}
