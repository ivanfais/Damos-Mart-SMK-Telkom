import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/complaint/complaint_cubit.dart';
import '../../core/utils/complaint_display_utils.dart';
import '../../core/utils/complaint_timeline_utils.dart';
import '../../data/models/complaint_model.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color screenBg = Color(0xFFF5F5F5);
  static const Color activeStepBg = Color(0xFFF3F4F6);
  static const Color lineColor = Color(0xFFD1D5DB);
  static const Color pendingCircle = Color(0xFFE5E7EB);
}

class ComplaintTrackingScreen extends StatefulWidget {
  const ComplaintTrackingScreen({
    super.key,
    required this.complaintId,
    this.initialComplaint,
    this.photoBytes,
  });

  final String complaintId;
  final ComplaintModel? initialComplaint;
  final Uint8List? photoBytes;

  @override
  State<ComplaintTrackingScreen> createState() => _ComplaintTrackingScreenState();
}

class _ComplaintTrackingScreenState extends State<ComplaintTrackingScreen> {
  ComplaintModel? _complaint;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _complaint = widget.initialComplaint;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshComplaint());
  }

  Future<void> _refreshComplaint() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    await context.read<ComplaintCubit>().loadComplaints();
    if (!mounted) return;

    final latest = context.read<ComplaintCubit>().findById(widget.complaintId);
    setState(() {
      _complaint = latest ?? _complaint ?? widget.initialComplaint;
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;

    return Scaffold(
      backgroundColor: _Ds.screenBg,
      body: Column(
        children: [
          SteadinessAppHeader(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile/chat');
              }
            },
          ),
          Expanded(
            child: complaint == null
                ? const Center(
                    child: CircularProgressIndicator(color: _Ds.primary),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        color: _Ds.primary,
                        onRefresh: _refreshComplaint,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTicketHeader(complaint),
                              const SizedBox(height: 20),
                              _buildSummaryCard(complaint),
                              const SizedBox(height: 16),
                              _buildTimelineCard(complaint),
                            ],
                          ),
                        ),
                      ),
                      if (_isRefreshing)
                        const Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: _Ds.primary,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: complaint == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/profile/chat');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTicketHeader(ComplaintModel complaint) {
    final badge = ComplaintTimelineUtils.badgeStyle(complaint.status);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Color(badge.background),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Color(badge.textColor),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ID Tiket: ${complaint.ticketNumber}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _Ds.primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ComplaintTimelineUtils.trackingSubtitle(complaint),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: _Ds.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ComplaintModel complaint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: _Ds.textPrimary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Subjek: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: complaint.subject,
                            style: const TextStyle(
                              color: _Ds.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dikirim pada ${ComplaintDisplayUtils.formatDateShort(complaint.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Ds.hint,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.photoBytes != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    widget.photoBytes!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: _Ds.border),
          ),
          Text(
            '"${complaint.description.trim()}"',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: _Ds.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ComplaintModel complaint) {
    final steps = ComplaintTimelineUtils.buildSteps(complaint);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Terkini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _Ds.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return _TimelineRow(
              step: step,
              showConnector: !isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.showConnector,
  });

  final ComplaintTimelineStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.state == ComplaintTimelineStepState.completed;
    final isActive = step.state == ComplaintTimelineStepState.active;
    final isRejected = step.title == 'Ditolak';
    final titleColor = isRejected
        ? const Color(0xFFD42427)
        : (isCompleted || isActive ? _Ds.primary : _Ds.hint);
    final subtitleColor = isCompleted || isActive ? _Ds.textSecondary : _Ds.hint;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        if (step.dateText != null) ...[
          const SizedBox(height: 2),
          Text(
            step.dateText!,
            style: TextStyle(
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
        ],
        if (step.detailText != null) ...[
          const SizedBox(height: 4),
          Text(
            step.detailText!,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: subtitleColor,
            ),
          ),
        ],
      ],
    );

    if (step.highlight) {
      content = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRejected ? const Color(0xFFFFF1F1) : _Ds.activeStepBg,
          borderRadius: BorderRadius.circular(10),
          border: isRejected ? Border.all(color: const Color(0xFFFECACA)) : null,
        ),
        child: content,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _StepIndicator(
                  state: step.state,
                  isRejected: isRejected,
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _Ds.lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 20 : 8),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.state,
    this.isRejected = false,
  });

  final ComplaintTimelineStepState state;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ComplaintTimelineStepState.completed:
        final color = isRejected ? const Color(0xFFD42427) : _Ds.primary;
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRejected ? Icons.close : Icons.check,
            size: 14,
            color: Colors.white,
          ),
        );
      case ComplaintTimelineStepState.active:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _Ds.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331B8C2E),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case ComplaintTimelineStepState.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _Ds.pendingCircle, width: 2),
          ),
        );
    }
  }
}
