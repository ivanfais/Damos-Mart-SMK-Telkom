import 'package:disc_core/disc_variant.dart';
import 'package:flutter/material.dart';

class DiscPickerScreen extends StatelessWidget {
  const DiscPickerScreen({super.key, required this.onSelected});

  final ValueChanged<DiscVariant> onSelected;

  static const _logoPath = 'assets/images/logo damos.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
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
                    _logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.store,
                      size: 64,
                      color: Color(0xFF1B8C2E),
                    ),
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
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih versi DISC yang ingin Anda gunakan. '
                'Pilihan bisa diubah nanti di Pengaturan Profil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: DiscVariant.pickerOrder.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variant = DiscVariant.pickerOrder[index];
                    return _DiscOptionCard(
                      variant: variant,
                      onTap: () => onSelected(variant),
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
  const _DiscOptionCard({required this.variant, required this.onTap});

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
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8C2E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_outlined, color: Color(0xFF1B8C2E)),
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
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variant.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}
