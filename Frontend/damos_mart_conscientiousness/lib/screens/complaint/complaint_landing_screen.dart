import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ComplaintLandingScreen extends StatelessWidget {
  const ComplaintLandingScreen({super.key});

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Ds.greenLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _Ds.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: _Ds.textPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Komplain & Retur',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Kebutuhanmu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: _Ds.borderLight),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Ajukan Komplain & Retur',
                    actionLabel: 'Mulai Laporan',
                    onTap: () => context.push('/complaint/form'),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.history_outlined,
                    title: 'Cek Status Approval',
                    actionLabel: 'Lacak Status',
                    onTap: () => context.push('/complaint/tickets'),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.event_note_outlined,
                    title: 'Jadwalkan Pengembalian',
                    actionLabel: 'Atur Jadwal',
                    onTap: () => context.push('/complaint/return-schedule'),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Riwayat Pengembalian',
                    actionLabel: 'Lihat Riwayat',
                    onTap: () => context.push('/complaint/return-history'),
                  ),
                ],
              ),
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                'permintaan akan ditinjau oleh Tim Koperasi dalam waktu 24-48 jam. '
                'Harap simpan kemasan asli untuk pengambilan retur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _Ds.textSecondary, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
