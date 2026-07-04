import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color timelineLine = Color(0xFFD1D5DB);
}

class _UsageStep {
  const _UsageStep({
    required this.number,
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final int number;
  final String title;
  final String description;
  final String imageAsset;
}

const _steps = <_UsageStep>[
  _UsageStep(
    number: 1,
    title: 'Login',
    description:
        'Login menggunakan email dan password yang telah didaftarkan saat proses registrasi',
    imageAsset: AppConstants.imageUsageLogin,
  ),
  _UsageStep(
    number: 2,
    title: 'Pilih Produk',
    description: 'Cari dan pilih produk yang diinginkan pada menu Katalog',
    imageAsset: AppConstants.imageUsagePickProduct,
  ),
  _UsageStep(
    number: 3,
    title: 'Pembayaran & Pesanan',
    description:
        'Masukkan produk ke keranjang, pilih metode pembayaran (Qris atau Bayar di Kasir), dan selesaikan transaksi untuk mendapatkan QR pengambilan.',
    imageAsset: AppConstants.imageUsagePayment,
  ),
  _UsageStep(
    number: 4,
    title: 'Ambil Pesanan',
    description:
        'Tunjukkan QR Pengambilan yang ada di menu Pesanan kepada petugas koperasi untuk mengambil barang Anda.',
    imageAsset: AppConstants.imageUsageQrCode,
  ),
  _UsageStep(
    number: 5,
    title: 'Komplain & Ulasan',
    description:
        'Jika ada kendala produk, gunakan menu \'Komplain\' untuk melapor dan pantau statusnya.',
    imageAsset: AppConstants.imageUsageComplaint,
  ),
];

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.arrow_back, color: _Ds.primary, size: 26),
          ),
          const Expanded(
            child: Text(
              'Tata Cara Penggunaan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _Ds.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int number) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _Ds.primary,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStep(_UsageStep step, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _buildStepCircle(step.number),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: _Ds.timelineLine,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: isLast ? 8 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _Ds.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _Ds.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _Ds.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        step.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: const Color(0xFFF5F5F5),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined, color: _Ds.textSecondary),
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    _buildStep(_steps[i], isLast: i == _steps.length - 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
