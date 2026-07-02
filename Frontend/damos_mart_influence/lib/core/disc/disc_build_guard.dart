import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'disc_app_config.dart';
import 'disc_variant_urls.dart';

/// Blocks wrong Flutter build when URL path does not match this project.
class DiscBuildGuard extends StatelessWidget {
  const DiscBuildGuard({super.key, required this.child});

  final Widget child;

  static bool get hasMismatch {
    if (!kIsWeb) return false;
    final fromPath = DiscVariantUrls.variantFromCurrentLocation();
    return fromPath != null && fromPath != DiscAppConfig.hostVariant;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasMismatch) return child;

    final expected = DiscVariantUrls.variantFromCurrentLocation()!;
    final actual = DiscAppConfig.hostVariant;

    return ColoredBox(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Build aplikasi tidak sesuai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'URL meminta tema ${expected.label}, tetapi yang berjalan adalah build ${actual.label}.\n\n'
                      'Ini terjadi jika Anda memakai flutter run satu proyek saja. '
                      'Untuk pindah tema dengan tampilan berbeda, jalankan:\n'
                      'Frontend/scripts/dev_single_domain.ps1',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buka: ${DiscVariantUrls.baseUrlFor(expected)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            DiscVariantUrls.navigateTo(
                              DiscVariantUrls.baseUrlFor(actual),
                            );
                          },
                          child: Text('Ke ${actual.label}'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            DiscVariantUrls.navigateTo(
                              DiscVariantUrls.baseUrlFor(expected),
                            );
                          },
                          child: Text('Ke ${expected.label}'),
                        ),
                      ],
                    ),
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
