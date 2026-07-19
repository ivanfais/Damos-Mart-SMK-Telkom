import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ComplaintSuccessScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintSuccessScreen({super.key, required this.complaint});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          Container(
            color: _Ds.primary,
            padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/home'),
                ),
                const Text(
                  'Komplain & Retur',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _Ds.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _Ds.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Laporan Berhasil Dibuat',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Terima kasih atas Laporan Anda.\nLaporan telah kami terima dan akan\nsegera diproses oleh tim kami.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          if (complaint.orderNumber != null) ...[
                            _row('ID Pesanan', complaint.orderNumber!),
                            const Divider(height: 18, color: Color(0xFFE0E0E0)),
                          ],
                          _row('ID Laporan', complaint.complaintNumber),
                          const Divider(height: 18, color: Color(0xFFE0E0E0)),
                          _row('Waktu', DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(complaint.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => context.push('/complaint/tickets'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Ds.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: _Ds.primary.withValues(alpha: 0.6), width: 2),
                          ),
                        ),
                        child: const Text(
                          'Lihat Status Laporan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
