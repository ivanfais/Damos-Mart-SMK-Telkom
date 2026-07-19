import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants/profile_menu_icons.dart';
import '../../core/storage/prefs_storage.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/history/purchase_history_content.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF3F4F6);
  static const Color avatarBg = Color(0xFFE52521);
  static const Color logoutRed = Color(0xFFE52521);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showHistory = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final fromRoute = uri.queryParameters['view'] == 'history';
    if (fromRoute != _showHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showHistory = fromRoute);
      });
    }
  }

  void _openHistory() {
    setState(() => _showHistory = true);
  }

  void _closeHistory() {
    setState(() => _showHistory = false);
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['view'] == 'history') {
      context.go('/profile');
    }
  }

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

  String _displayFirstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _displayNickname(UserModel user) {
    return PrefsStorage.instance.getUserNickname(user.id) ??
        _displayFirstName(user.fullName);
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
          _displayNickname(user),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
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
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    assert(icon != null || leading != null, 'icon atau leading wajib diisi');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            leading ?? Icon(icon, color: _Ds.primary, size: ProfileMenuIcons.size),
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
          foregroundColor: _Ds.logoutRed,
          side: const BorderSide(color: _Ds.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(ProfileMenuIcons.logout, size: 20, color: _Ds.logoutRed),
        label: const Text(
          'Keluar Sesi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _Ds.logoutRed,
          ),
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
              SteadinessAppHeader(
                onBack: _showHistory ? _closeHistory : null,
              ),
              Expanded(
                child: _showHistory
                    ? const PurchaseHistoryContent()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: _buildProfileHeader(user)),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Pengaturan Akun'),
                            _buildMenuCard([
                              _buildMenuTile(
                                icon: ProfileMenuIcons.editProfile,
                                title: 'Edit Profil',
                                onTap: () => context.push('/profile/edit'),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: ProfileMenuIcons.changePassword,
                                title: 'Ubah Kata Sandi',
                                onTap: () => context.push('/profile/change-password'),
                              ),
                            ]),
                            const SizedBox(height: 22),
                            _buildSectionTitle('Preferensi Aplikasi'),
                            _buildMenuCard([
                              _buildMenuTile(
                                icon: ProfileMenuIcons.language,
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
                                icon: ProfileMenuIcons.notifications,
                                title: 'Notifikasi',
                                onTap: () => context.go('/notifications?from=profile'),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: ProfileMenuIcons.orderHistory,
                                title: 'Riwayat Pemesanan',
                                onTap: _openHistory,
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: ProfileMenuIcons.complaint,
                                title: 'Komplain',
                                onTap: () => context.push('/profile/chat'),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                leading: ProfileMenuIcons.usageGuideIcon(),
                                title: 'Tata Cara Penggunaan',
                                onTap: () => context.push('/profile/usage-guide'),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: ProfileMenuIcons.discTheme,
                                title: 'Gaya Aplikasi DISC',
                                onTap: () => context.push('/profile/disc-theme'),
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
