import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class ComplaintSubmittedScreen extends StatelessWidget {
  const ComplaintSubmittedScreen({
    super.key,
    required this.ticketNumber,
    required this.complaintId,
    required this.orderId,
  });

  final String ticketNumber;
  final String complaintId;
  final String orderId;

  static const Color _ticketBoxFill = Color(0xFFE8F5E9);
  static const Color _ticketBorder = Color(0xFF008816);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosPageHeader(
            title: 'Bantuan & Komplain',
            showBackButton: true,
            backgroundColor: DamosDominanceColors.primary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: DamosDominanceColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: DamosDominanceColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Komplain Berhasil Dikirim!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Terima kasih, laporan Anda telah kami terima.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _ticketBoxFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ticketBorder),
                    ),
                    child: Text(
                      ticketNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: DamosDominanceColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tim koperasi akan meninjau laporan Anda dalam 1x24 jam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go('/complaints/$complaintId'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DamosDominanceColors.primary,
                        side: const BorderSide(color: DamosDominanceColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lihat Status Komplain',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/orders/$orderId'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DamosDominanceColors.primary,
                        foregroundColor: DamosDominanceColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Kembali ke Detail Pesanan',
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
