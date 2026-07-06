import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFD42427);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class _TimelineStep {
  final String title;
  final String description;
  final DateTime? date;
  final bool isDone;
  final bool isRejected;

  const _TimelineStep({
    required this.title,
    required this.description,
    required this.date,
    required this.isDone,
    this.isRejected = false,
  });
}

class ComplaintStatusScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintStatusScreen({super.key, required this.complaint});

  List<_TimelineStep> _buildSteps() {
    final status = complaint.status;
    final isDecided = status == ComplaintStatus.resolved || status == ComplaintStatus.rejected;
    final isReviewed = status != ComplaintStatus.open;
    final isApproved = status == ComplaintStatus.resolved;
    final isRejected = status == ComplaintStatus.rejected;

    final decisionDate = complaint.resolvedAt ?? complaint.respondedAt;

    String decisionDesc;
    if (isApproved) {
      decisionDesc = 'Permintaan disetujui';
    } else if (isRejected) {
      decisionDesc = complaint.adminResponse != null && complaint.adminResponse!.isNotEmpty
          ? 'Permintaan ditolak (${complaint.adminResponse})'
          : 'Permintaan ditolak';
    } else {
      decisionDesc = '-';
    }

    return [
      _TimelineStep(
        title: 'Tiket Komplain & Retur terkirim',
        description: 'Permintaan dibuat oleh user',
        date: complaint.createdAt,
        isDone: true,
      ),
      _TimelineStep(
        title: 'Tiket sedang dalam peninjauan',
        description: isReviewed ? 'Permintaan laporan ditinjau' : 'Menunggu peninjauan',
        date: isReviewed ? (complaint.respondedAt ?? complaint.createdAt) : null,
        isDone: isReviewed,
      ),
      _TimelineStep(
        title: 'Disetujui/Ditolak',
        description: isDecided ? decisionDesc : '-',
        date: isDecided ? decisionDate : null,
        isDone: isDecided,
        isRejected: isRejected,
      ),
      _TimelineStep(
        title: isRejected ? 'Ready for Return' : 'Pengembalian Barang Siap',
        description: isApproved ? 'Atur Jadwal Pengembalian' : '-',
        date: isDecided ? decisionDate : null,
        isDone: isDecided,
        isRejected: isRejected,
      ),
    ];
  }

  void _onSchedulePressed(BuildContext context) {
    context.push('/complaint/return-schedule', extra: complaint);
  }

  Widget _buildStepIcon(_TimelineStep step) {
    if (!step.isDone) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.circle_outlined, size: 16, color: _Ds.textSecondary),
      );
    }
    final color = step.isRejected ? _Ds.red : _Ds.primary;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(step.isRejected ? Icons.close : Icons.check, size: 16, color: Colors.white),
    );
  }

  Widget _buildStep(_TimelineStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildStepIcon(step),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: step.isDone ? (step.isRejected ? _Ds.red : _Ds.primary) : _Ds.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  step.date != null
                      ? '${DateFormat('dd MMM, HH:mm', 'id_ID').format(step.date!)} • ${step.description}'
                      : step.description,
                  style: const TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final canSchedule = complaint.status == ComplaintStatus.resolved;
    final lastUpdate = complaint.resolvedAt ?? complaint.respondedAt ?? complaint.createdAt;

    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(title: 'Komplain & Retur', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Pengajuan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update terakhir : ${DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(lastUpdate)}',
                    style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: _Ds.borderLight),
                  const SizedBox(height: 12),
                  Text(
                    'Nomor Tiket : ${complaint.complaintNumber}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Ds.greenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pelacakan Status Pengembalian',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        ...steps.asMap().entries.map(
                              (entry) => _buildStep(entry.value, entry.key == steps.length - 1),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canSchedule ? () => _onSchedulePressed(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Jadwalkan Pengembalian',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
