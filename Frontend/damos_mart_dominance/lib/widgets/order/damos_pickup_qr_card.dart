import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/damos_dominance_colors.dart';

/// Kartu QR pengambilan pesanan di koperasi (status Siap Ambil).
class DamosPickupQrCard extends StatelessWidget {
  final String qrData;

  const DamosPickupQrCard({
    super.key,
    required this.qrData,
  });

  static const Color _qrisRed = Color(0xFFE53935);
  static const double _cardRadius = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          const Text(
            'QR Pengambilan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DamosDominanceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildQrisFrame(),
          const SizedBox(height: 16),
          const Text(
            'Tunjukkan QR ini kepada petugas koperasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: DamosDominanceColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisFrame() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 24,
            bottom: 24,
            child: _sidePattern(alignLeft: true),
          ),
          Positioned(
            right: 0,
            top: 24,
            bottom: 24,
            child: _sidePattern(alignLeft: false),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: DamosDominanceColors.fieldBorder),
            ),
            child: Column(
              children: [
                const Text(
                  'QRIS  ·  GPN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DAMOS MART',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'NMID: ID1023245678901',
                  style: TextStyle(
                    fontSize: 11,
                    color: DamosDominanceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: DamosDominanceColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cek aplikasi penyelenggara di: www.aspi-qris.id',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: DamosDominanceColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidePattern({required bool alignLeft}) {
    return SizedBox(
      width: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (index) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: index.isEven ? _qrisRed : Colors.white,
              border: Border.all(color: _qrisRed.withValues(alpha: 0.35)),
            ),
          ),
        ),
      ),
    );
  }
}
