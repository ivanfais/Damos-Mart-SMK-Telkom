import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';

class ComplaintDisplayColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBg = Color(0xFFF9FAFB);
  static const Color rejectedRed = Color(0xFFD42427);
  static const Color resolvedBg = Color(0xFF1B8C2E);
  static const Color rejectedBg = Color(0xFFE5E7EB);
  static const Color rejectedText = Color(0xFF6B7280);
  static const Color progressBg = Color(0xFFE0F2E4);
  static const Color progressText = Color(0xFF1B8C2E);
}

class ComplaintDisplayUtils {
  ComplaintDisplayUtils._();

  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(local);
  }

  static String formatDateShort(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateFormat('d MMM yyyy', 'id_ID').format(local);
  }

  static String statusLabel(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return 'Menunggu';
      case ComplaintStatus.inProgress:
        return 'Diproses';
      case ComplaintStatus.resolved:
        return 'Selesai';
      case ComplaintStatus.rejected:
        return 'Ditolak';
    }
  }

  static Color statusBackground(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.resolved:
        return ComplaintDisplayColors.resolvedBg;
      case ComplaintStatus.rejected:
        return ComplaintDisplayColors.rejectedBg;
      case ComplaintStatus.inProgress:
        return ComplaintDisplayColors.progressBg;
      default:
        return const Color(0xFFFFF3CD);
    }
  }

  static Color statusTextColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.resolved:
        return Colors.white;
      case ComplaintStatus.rejected:
        return ComplaintDisplayColors.rejectedText;
      case ComplaintStatus.inProgress:
        return ComplaintDisplayColors.progressText;
      default:
        return const Color(0xFF856404);
    }
  }

  static String? footerMeta(ComplaintModel complaint) {
    if (complaint.status == ComplaintStatus.rejected) {
      final reason = complaint.adminResponseText;
      if (reason != null) {
        return reason.length > 40 ? '${reason.substring(0, 40).trim()}...' : reason;
      }
      return 'Alasan tidak valid';
    }

    if (complaint.status == ComplaintStatus.resolved && complaint.adminResponseText != null) {
      return 'Tanggapan Staff Tersedia';
    }

    return null;
  }

  static Color? footerMetaColor(ComplaintModel complaint) {
    if (complaint.status == ComplaintStatus.rejected) {
      return ComplaintDisplayColors.rejectedRed;
    }
    if (complaint.status == ComplaintStatus.resolved && complaint.adminResponseText != null) {
      return ComplaintDisplayColors.textSecondary;
    }
    return null;
  }

  static String snippet(String description, {int maxLength = 72}) {
    final trimmed = description.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength).trimRight()}...';
  }
}
