import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class ComplaintSubmittedScreen extends StatelessWidget {
  const ComplaintSubmittedScreen({
    super.key,
    required this.ticketNumber,
  });

  final String ticketNumber;

  static const Color _ticketBoxFill = Color(0xFFD4EDDA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DamosPageHeader(
            title: 'Bantuan & Komplain',
            showBackButton: true,
            onBack: () => context.go('/profile'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Keluhan Terkirim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tim koperasi akan meninjau keluhanmu dan memberikan respons dalam 1x24 jam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _ticketBoxFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nomor Tiket: $ticketNumber',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/complaints'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DamosDominanceColors.primary,
                        foregroundColor: DamosDominanceColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Kirim Keluhan Lagi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
