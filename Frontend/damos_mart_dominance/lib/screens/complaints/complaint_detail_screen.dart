import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/notifications/complaint_realtime_service.dart';import '../../core/utils/complaint_status_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_issue_option.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  final String complaintId;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  static const _cardRadius = 8.0;

  final _repository = ComplaintRepository();
  ComplaintModel? _complaint;
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
    _realtimeSub = ComplaintRealtimeService.instance.updates.listen((data) {
      final complaintId = data['complaintId']?.toString();
      if (complaintId != widget.complaintId) return;
      _loadComplaint(silent: true);
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadComplaint({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final complaint = await _repository.findComplaintById(widget.complaintId);
      if (!mounted) return;
      if (complaint == null) {
        setState(() {
          _loading = false;
          _error = 'Komplain tidak ditemukan';
        });
        return;
      }
      setState(() {
        _complaint = complaint;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _copyTicket(String ticket) async {
    await Clipboard.setData(ClipboardData(text: ticket));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor tiket disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: DamosDominanceColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ComplaintStatusTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        theme.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.foregroundColor,
        ),
      ),
    );
  }

  Widget _timelineDot(Color color, {bool active = false}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: active ? color : Colors.white,
      ),
      child: active
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTimeline(ComplaintModel complaint) {
    final steps = ComplaintStatusHelper.buildTimeline(complaint);
    final footerBg = ComplaintStatusHelper.footerBackgroundColor(complaint);
    final footerColor = ComplaintStatusHelper.footerTextColor(complaint);

    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Status',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              final dotColor = ComplaintStatusHelper.stepDotColor(step);
              final titleColor = ComplaintStatusHelper.stepTitleColor(step);
              final isActive = step.isActive;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _timelineDot(dotColor, active: isActive),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 52,
                          color: DamosDominanceColors.fieldBorder,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          if (step.timestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.format(step.timestamp!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: DamosDominanceColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DamosDominanceColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: footerBg,
                borderRadius: BorderRadius.circular(_cardRadius),
              ),
              child: Text(
                ComplaintStatusHelper.footerMessage(complaint),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: footerColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ComplaintModel complaint) {
    final badge = ComplaintStatusHelper.badgeTheme(complaint);
    final ticket = complaint.displayTicketNumber;
    final parsed = ComplaintSubjectParser.parse(complaint.subject);
    final issueTypeLabel =
        parsed.issueType ?? ComplaintStatusHelper.categoryLabel(complaint.category);
    final subjectLabel = complaint.category == 'PRODUCT' ? 'Produk' : 'Perihal';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No. Tiket',
                          style: TextStyle(
                            fontSize: 12,
                            color: DamosDominanceColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              ticket,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: DamosDominanceColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () => _copyTicket(ticket),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy_outlined,
                                  size: 20,
                                  color: DamosDominanceColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _statusBadge(badge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Komplain',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: DamosDominanceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: DamosDominanceColors.fieldBorder),
                        const SizedBox(height: 8),
                        _infoRow(subjectLabel, parsed.title),
                        _infoRow(
                          'Tanggal Komplain',
                          DateFormatter.format(complaint.createdAt),
                        ),
                        _infoRow('Jenis Kendala', issueTypeLabel),
                        _infoRow('Deskripsi', complaint.description),
                        if (complaint.order?.orderNumber != null)
                          _infoRow(
                            'No. Pesanan',
                            complaint.order!.orderNumber,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeline(complaint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Detail Komplain',
            showBackButton: true,
            backgroundColor: DamosDominanceColors.primary,
          ),
          Expanded(
            child: _loading
                ? const DamosOrderDetailShimmer()
                : _error != null
                    ? ErrorState(
                        message: _error!,
                        onRetry: _loadComplaint,
                      )
                    : _complaint != null
                        ? _buildContent(_complaint!)
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
