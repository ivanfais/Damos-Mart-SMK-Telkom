import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/disc/disc_app_launcher.dart';
import '../../core/disc/disc_app_config.dart';
import '../../core/disc/disc_variant.dart';
import '../../core/storage/prefs_storage.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF9F9F9);
}

class DiscThemeSettingsScreen extends StatefulWidget {
  const DiscThemeSettingsScreen({super.key});

  @override
  State<DiscThemeSettingsScreen> createState() => _DiscThemeSettingsScreenState();
}

class _DiscThemeSettingsScreenState extends State<DiscThemeSettingsScreen> {
  DiscVariant? _selected;

  @override
  void initState() {
    super.initState();
    _selected = DiscAppLauncher.activeVariant;
  }

  Future<void> _applyVariant(DiscVariant variant) async {
    if (_selected == variant) return;

    setState(() => _selected = variant);

    final redirected = await DiscAppLauncher.switchToVariant(variant);
    if (!mounted) return;
    if (redirected) return;

    if (kIsWeb && variant != DiscAppConfig.hostVariant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DiscAppLauncher.singleBuildSwitchHint)),
      );
      setState(() => _selected = DiscAppLauncher.activeVariant);
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosPageHeader(
            title: 'Gaya Aplikasi DISC',
            showBackButton: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Pilih versi aplikasi yang ingin Anda gunakan. Aplikasi akan dimuat ulang ke splash screen setelah Anda memilih.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: _Ds.textSecondary),
                ),
                const SizedBox(height: 16),
                ...DiscVariant.values.map((variant) {
                  final isSelected = _selected == variant;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _applyVariant(variant),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _Ds.primary : _Ds.borderLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? _Ds.primary : _Ds.textSecondary,
                              ),
                              const SizedBox(width: 12),
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _Ds.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
