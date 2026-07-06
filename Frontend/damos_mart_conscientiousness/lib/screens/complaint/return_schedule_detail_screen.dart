import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ReturnScheduleDetailScreen extends StatelessWidget {
  final ReturnScheduleModel schedule;

  const ReturnScheduleDetailScreen({super.key, required this.schedule});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
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
          const DamosPageHeader(title: 'Riwayat Pengembalian', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.productName ?? 'Produk',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: _Ds.borderLight),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _Ds.borderLight),
                    ),
                    child: Column(
                      children: [
                        _row('Id Pesanan', schedule.orderNumber ?? '-'),
                        const Divider(height: 1, color: _Ds.borderLight),
                        _row('Nomor Laporan', schedule.complaintNumber),
                        const Divider(height: 1, color: _Ds.borderLight),
                        _row(
                          'Waktu Pengambilan',
                          '${DateFormat('dd/MMMM/yyyy', 'id_ID').format(schedule.returnDate)} • '
                          '${schedule.timeSlot.label} (${schedule.timeSlot.timeRange})',
                        ),
                      ],
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
