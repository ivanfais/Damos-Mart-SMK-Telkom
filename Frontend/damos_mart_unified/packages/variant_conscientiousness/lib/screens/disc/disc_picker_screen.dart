import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/disc/disc_app_launcher.dart';
import '../../core/disc/disc_app_config.dart';
import '../../core/disc/disc_variant.dart';
import '../../config/app_constants.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF9F9F9);
}

class DiscPickerScreen extends StatelessWidget {
  const DiscPickerScreen({super.key});

  Future<void> _selectVariant(BuildContext context, DiscVariant variant) async {
    final redirected = await DiscAppLauncher.switchToVariant(variant);
    if (!context.mounted) return;
    if (redirected) return;

    if (kIsWeb && variant != DiscAppConfig.hostVariant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DiscAppLauncher.singleBuildSwitchHint)),
      );
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 88,
                  child: Image.asset(
                    AppConstants.imageLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 64, color: _Ds.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Gaya Aplikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _Ds.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih versi DISC yang ingin Anda gunakan. Pilihan bisa diubah nanti di Pengaturan Profil.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: _Ds.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: DiscVariant.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variant = DiscVariant.values[index];
                    return _DiscOptionCard(
                      variant: variant,
                      onTap: () => _selectVariant(context, variant),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscOptionCard extends StatelessWidget {
  const _DiscOptionCard({
    required this.variant,
    required this.onTap,
  });

  final DiscVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Ds.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _Ds.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_outlined, color: _Ds.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _Ds.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variant.description,
                      style: const TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: _Ds.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
