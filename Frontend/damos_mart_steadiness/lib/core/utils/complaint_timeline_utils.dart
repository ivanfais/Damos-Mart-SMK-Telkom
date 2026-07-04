import '../../data/models/complaint_model.dart';

enum ComplaintTimelineStepState { completed, active, pending }

class ComplaintTimelineStep {
  const ComplaintTimelineStep({
    required this.title,
    this.dateText,
    this.detailText,
    required this.state,
    this.highlight = false,
  });

  final String title;
  final String? dateText;
  final String? detailText;
  final ComplaintTimelineStepState state;
  final bool highlight;
}

class ComplaintTimelineBadgeStyle {
  const ComplaintTimelineBadgeStyle({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final int background;
  final int textColor;
}

class ComplaintTimelineUtils {
  ComplaintTimelineUtils._();

  static const int _badgeGrayBg = 0xFFE5E7EB;
  static const int _badgeGrayText = 0xFF4B5563;
  static const int _badgeGreenBg = 0xFFE0F2E4;
  static const int _badgeGreenText = 0xFF1B8C2E;
  static const int _badgeRedBg = 0xFFFEE2E2;
  static const int _badgeRedText = 0xFFD42427;
  static const int _badgeAmberBg = 0xFFFFF3CD;
  static const int _badgeAmberText = 0xFF856404;

  static ComplaintTimelineBadgeStyle badgeStyle(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return const ComplaintTimelineBadgeStyle(
          label: 'MENUNGGU TINJAUAN',
          background: _badgeAmberBg,
          textColor: _badgeAmberText,
        );
      case ComplaintStatus.inProgress:
        return const ComplaintTimelineBadgeStyle(
          label: 'SEDANG DIPROSES',
          background: _badgeGrayBg,
          textColor: _badgeGrayText,
        );
      case ComplaintStatus.resolved:
        return const ComplaintTimelineBadgeStyle(
          label: 'SELESAI',
          background: _badgeGreenBg,
          textColor: _badgeGreenText,
        );
      case ComplaintStatus.rejected:
        return const ComplaintTimelineBadgeStyle(
          label: 'DITOLAK',
          background: _badgeRedBg,
          textColor: _badgeRedText,
        );
    }
  }

  static String trackingSubtitle(ComplaintModel complaint) {
    switch (complaint.status) {
      case ComplaintStatus.open:
        return 'Komplain Anda telah diterima dan menunggu peninjauan admin.';
      case ComplaintStatus.inProgress:
        return 'Dipindahkan ke bagian teknis untuk pengecekan detail.';
      case ComplaintStatus.resolved:
        return 'Komplain Anda telah diselesaikan oleh tim kami.';
      case ComplaintStatus.rejected:
        return 'Komplain tidak dapat diproses lebih lanjut.';
    }
  }

  static List<ComplaintTimelineStep> buildSteps(ComplaintModel complaint) {
    final isResolved = complaint.status == ComplaintStatus.resolved;
    final isRejected = complaint.status == ComplaintStatus.rejected;
    final isInProgress = complaint.status == ComplaintStatus.inProgress;
    final isTerminal = isResolved || isRejected;
    final adminResponse = complaint.adminResponseText;

    final sent = ComplaintTimelineStep(
      title: 'Komplain Dikirim',
      dateText: _formatStepDate(complaint.createdAt),
      state: ComplaintTimelineStepState.completed,
    );

    final reviewedCompleted = complaint.respondedAt != null ||
        isInProgress ||
        isTerminal;

    final reviewed = ComplaintTimelineStep(
      title: 'Ditinjau oleh Admin',
      dateText: reviewedCompleted
          ? _formatStepDate(complaint.respondedAt ?? complaint.createdAt)
          : null,
      state: reviewedCompleted
          ? ComplaintTimelineStepState.completed
          : ComplaintTimelineStepState.pending,
    );

    final ComplaintTimelineStep processing;
    if (isInProgress) {
      processing = const ComplaintTimelineStep(
        title: 'Sedang Diproses',
        detailText: 'Tim kami sedang mengecek produk terkait dan mencocokkan dengan data stok.',
        state: ComplaintTimelineStepState.active,
        highlight: true,
      );
    } else if (isTerminal) {
      processing = const ComplaintTimelineStep(
        title: 'Sedang Diproses',
        dateText: null,
        detailText: 'Proses penanganan komplain telah dilakukan.',
        state: ComplaintTimelineStepState.completed,
      );
    } else {
      processing = const ComplaintTimelineStep(
        title: 'Sedang Diproses',
        detailText: 'Menunggu proses penanganan lebih lanjut.',
        state: ComplaintTimelineStepState.pending,
      );
    }

    final ComplaintTimelineStep finished;
    if (isResolved) {
      finished = ComplaintTimelineStep(
        title: 'Selesai',
        dateText: _formatStepDate(
          complaint.resolvedAt ?? complaint.respondedAt ?? complaint.createdAt,
        ),
        detailText: adminResponse ?? 'Komplain telah diselesaikan oleh tim koperasi.',
        state: ComplaintTimelineStepState.completed,
        highlight: adminResponse != null,
      );
    } else if (isRejected) {
      finished = ComplaintTimelineStep(
        title: 'Ditolak',
        dateText: _formatStepDate(
          complaint.resolvedAt ?? complaint.respondedAt ?? complaint.createdAt,
        ),
        detailText: adminResponse ?? 'Komplain ditolak oleh tim koperasi.',
        state: ComplaintTimelineStepState.completed,
        highlight: true,
      );
    } else {
      finished = const ComplaintTimelineStep(
        title: 'Selesai',
        detailText: 'Menunggu keputusan akhir',
        state: ComplaintTimelineStepState.pending,
      );
    }

    return [sent, reviewed, processing, finished];
  }

  static String _formatStepDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
  }
}
