import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ReturnHistoryScreen extends StatefulWidget {
  const ReturnHistoryScreen({super.key});

  @override
  State<ReturnHistoryScreen> createState() => _ReturnHistoryScreenState();
}

class _ReturnHistoryScreenState extends State<ReturnHistoryScreen> {
  final ComplaintRepository _repository = ComplaintRepository();
  List<ReturnScheduleModel>? _schedules;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _schedules = null;
      _errorMessage = null;
    });
    try {
      final schedules = await _repository.getMyReturnSchedules();
      if (!mounted) return;
      setState(() => _schedules = schedules);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memuat riwayat pengembalian. Coba lagi ya!');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 140, height: 1, color: _Ds.borderLight),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Riwayat Pengembalian',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _Ds.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ReturnScheduleModel schedule) {
    return GestureDetector(
      onTap: () => context.push('/complaint/return-schedule/detail', extra: schedule),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.productName ?? 'Produk',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${schedule.orderNumber ?? '-'} • ${schedule.complaintNumber}',
              style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _Ds.borderLight),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(schedule.createdAt),
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
                Text(
                  '${schedule.timeSlot.label} • ${schedule.timeSlot.timeRange}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _Ds.primary),
                ),
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
          const DamosPageHeader(title: 'Riwayat Pengembalian', showBackButton: true),
          Expanded(
            child: _errorMessage != null
                ? ErrorState(message: _errorMessage!, onRetry: _load)
                : _schedules == null
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, __) => const LoadingShimmer(
                          width: double.infinity,
                          height: 130,
                          borderRadius: 14,
                        ),
                      )
                    : _schedules!.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _Ds.primary,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _schedules!.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) => _buildCard(_schedules![index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
