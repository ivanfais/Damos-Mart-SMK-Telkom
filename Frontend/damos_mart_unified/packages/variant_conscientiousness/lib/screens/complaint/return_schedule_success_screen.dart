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

class ReturnScheduleSuccessScreen extends StatelessWidget {
  final ReturnScheduleModel schedule;

  const ReturnScheduleSuccessScreen({super.key, required this.schedule});

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
          Flexible(child: value),
        ],
      ),
    );
  }

  void _goToLanding(BuildContext context) => context.go('/complaint');

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
                  onPressed: () => _goToLanding(context),
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
                      decoration: BoxDecoration(color: _Ds.primary, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pengembalian Berhasil Dijadwalkan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Terimakasih telah mempercayai Damos Mart',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.productName ?? 'Produk',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                          ),
                          const Divider(height: 18, color: Color(0xFFE0E0E0)),
                          _row(
                            'Id Pesanan',
                            Text(
                              schedule.orderNumber ?? '-',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                            ),
                          ),
                          const Divider(height: 18, color: Color(0xFFE0E0E0)),
                          _row(
                            'Nomor Laporan',
                            Text(
                              schedule.complaintNumber,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                            ),
                          ),
                          const Divider(height: 18, color: Color(0xFFE0E0E0)),
                          _row(
                            'Waktu Pengembalian',
                            Text(
                              '${DateFormat('dd/MMMM/yyyy', 'id_ID').format(schedule.returnDate)}\n'
                              '${schedule.timeSlot.label}\n${schedule.timeSlot.timeRange}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToLanding(context),
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
                          'Selesai dan Simpan',
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
