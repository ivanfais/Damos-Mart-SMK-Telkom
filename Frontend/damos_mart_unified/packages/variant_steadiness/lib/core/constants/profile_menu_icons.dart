import 'package:flutter/material.dart';
import '../../widgets/profile/usage_guide_menu_icon.dart';

/// Ikon menu profil Steadiness — diselaraskan dengan mockup Profil Pengguna (DISC S).
class ProfileMenuIcons {
  ProfileMenuIcons._();

  static const double size = 24;

  /// Selaras dengan ikon Material menu profil lainnya.
  static const double usageGuideIconSize = 24;

  /// Edit Profil — siluet orang outline.
  static const IconData editProfile = Icons.person_outline_rounded;

  /// Ubah Kata Sandi — gembok outline.
  static const IconData changePassword = Icons.lock_outline_rounded;

  /// Bahasa — globe.
  static const IconData language = Icons.language_outlined;

  /// Notifikasi — lonceng outline.
  static const IconData notifications = Icons.notifications_outlined;

  /// Riwayat Pemesanan — jam dengan panah melingkar (history).
  static const IconData orderHistory = Icons.history_outlined;

  /// Komplain — tanda tanya dalam lingkaran.
  static const IconData complaint = Icons.help_outline_rounded;

  /// Tata Cara Penggunaan — ikon buku dari asset mockup.
  static Widget usageGuideIcon() {
    return const UsageGuideMenuIcon(size: usageGuideIconSize);
  }

  /// Gaya Aplikasi DISC — palet warna.
  static const IconData discTheme = Icons.palette_outlined;

  /// Keluar Sesi — panah keluar dari kotak.
  static const IconData logout = Icons.logout_rounded;
}
