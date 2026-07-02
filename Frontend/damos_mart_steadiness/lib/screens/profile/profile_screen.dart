import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../widgets/common/user_avatar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF3F4F6);
  static const Color avatarBg = Color(0xFFE52521);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    PopUpAlert.show(
      context: context,
      title: 'Keluar Sesi?',
      description: 'Apakah kamu yakin ingin keluar dari akun Damos Mart?',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isError: true,
      onConfirm: () {
        context.read<AuthBloc>().add(LoggedOut());
        context.go('/login');
      },
    );
  }

  String _displayNis(UserModel user) {
    if (user.ssoId != null && user.ssoId!.trim().isNotEmpty) {
      return 'NIS: ${user.ssoId}';
    }
    return 'NIS: -';
  }

  String _displayClassBadge(UserModel user) {
    return 'Siswa Kelas SMK Telkom Jakarta';
  }

  String _displayFirstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        UserAvatar(
          avatarUrl: user.avatarUrl,
          radius: 46,
          backgroundColor: _Ds.avatarBg,
          iconColor: Colors.white,
          iconSize: 44,
        ),
        const SizedBox(height: 14),
        Text(
          _displayFirstName(user.fullName),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _displayNis(user),
          style: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _Ds.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Ds.border),
          ),
          child: Text(
            _displayClassBadge(user),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _Ds.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _Ds.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _Ds.textPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: subtitle == null
                  ? Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _Ds.textPrimary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _Ds.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, color: _Ds.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: _Ds.border, indent: 52);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: _Ds.cardBg,
          foregroundColor: _Ds.primary,
          side: const BorderSide(color: _Ds.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Keluar Sesi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Center(
              child: CircularProgressIndicator(color: _Ds.primary),
            );
          }

          final user = state.user;

          return Column(
            children: [
              const SteadinessAppHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildProfileHeader(user)),
                      const SizedBox(height: 28),
                      _buildSectionTitle('Pengaturan Akun'),
                      _buildMenuCard([
                        _buildMenuTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profil',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _buildDivider(),
                        _buildMenuTile(
                          icon: Icons.lock_outline,
                          title: 'Ubah Kata Sandi',
                          onTap: () {
                            PopUpAlert.show(
                              context: context,
                              title: 'Ubah Kata Sandi',
                              description:
                                  'Fitur ubah kata sandi akan segera tersedia. Untuk sementara, silakan hubungi petugas IT sekolah.',
                              isError: false,
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _buildSectionTitle('Preferensi Aplikasi'),
                      _buildMenuCard([
                        _buildMenuTile(
                          icon: Icons.language_outlined,
                          title: 'Bahasa',
                          subtitle: 'Bahasa Indonesia',
                          onTap: () {
                            PopUpAlert.show(
                              context: context,
                              title: 'Bahasa',
                              description: 'Bahasa aplikasi saat ini: Bahasa Indonesia.',
                              isError: false,
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuTile(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifikasi',
                          onTap: () {
                            PopUpAlert.show(
                              context: context,
                              title: 'Notifikasi',
                              description: 'Notifikasi pesanan dan antrean kamu aktif.',
                              isError: false,
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuTile(
                          icon: Icons.help_outline,
                          title: 'Komplain',
                          onTap: () => context.push('/profile/chat'),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
