import 'package:flutter/material.dart';
import '../../data/models/complaint_model.dart';

class ComplaintStatusTheme {
  const ComplaintStatusTheme({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
}

enum ComplaintTimelineStepState { completed, active, pending }

class ComplaintTimelineStep {
  const ComplaintTimelineStep({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.state,
    required this.accentColor,
  });

  final String title;
  final String description;
  final DateTime? timestamp;
  final ComplaintTimelineStepState state;
  final Color accentColor;

  bool get isActive => state == ComplaintTimelineStepState.active;
}

class ComplaintStatusHelper {
  static const Color _blue = Color(0xFF1A73E8);
  static const Color _blueBg = Color(0xFFE8F0FE);
  static const Color _orange = Color(0xFFE65100);
  static const Color _orangeBg = Color(0xFFFFF3E0);
  static const Color _green = Color(0xFF008816);
  static const Color _greenBg = Color(0xFFE8F5E9);
  static const Color _red = Color(0xFFD42427);
  static const Color _redBg = Color(0xFFFFEBEE);
  static const Color _gray = Color(0xFF9CA3AF);

  static ComplaintStatusTheme badgeTheme(ComplaintModel complaint) {
    switch (complaint.status) {
      case 'OPEN':
        return const ComplaintStatusTheme(
          label: 'Komplain Dikirim',
          backgroundColor: _blueBg,
          foregroundColor: _blue,
          accentColor: _blue,
        );
      case 'IN_PROGRESS':
        return const ComplaintStatusTheme(
          label: 'Sedang Ditinjau',
          backgroundColor: _orangeBg,
          foregroundColor: _orange,
          accentColor: _orange,
        );
      case 'RESOLVED':
        if (complaint.resolvedAt != null &&
            complaint.adminResponse != null &&
            complaint.adminResponse!.isNotEmpty) {
          return const ComplaintStatusTheme(
            label: 'Selesai',
            backgroundColor: _greenBg,
            foregroundColor: _green,
            accentColor: _green,
          );
        }
        return const ComplaintStatusTheme(
          label: 'Disetujui',
          backgroundColor: _greenBg,
          foregroundColor: _green,
          accentColor: _green,
        );
      case 'REJECTED':
        return const ComplaintStatusTheme(
          label: 'Ditolak',
          backgroundColor: _redBg,
          foregroundColor: _red,
          accentColor: _red,
        );
      default:
        return const ComplaintStatusTheme(
          label: 'Komplain Dikirim',
          backgroundColor: _blueBg,
          foregroundColor: _blue,
          accentColor: _blue,
        );
    }
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'PRODUCT':
        return 'Produk';
      case 'SERVICE':
        return 'Pelayanan';
      case 'ORDER':
        return 'Pesanan & Transaksi';
      case 'QUEUE':
        return 'Antrean/Pengambilan';
      case 'OTHER':
        return 'Lainnya';
      default:
        return category;
    }
  }

  static String footerMessage(ComplaintModel complaint) {
    switch (complaint.status) {
      case 'OPEN':
        return 'Kami akan meninjau laporan Anda maksimal 1x24 jam.';
      case 'IN_PROGRESS':
        return 'Mohon tunggu, admin akan segera memproses laporan Anda.';
      case 'RESOLVED':
        return 'Permasalahan Anda telah diselesaikan. Terima kasih!';
      case 'REJECTED':
        return 'Jika ada pertanyaan, silakan hubungi petugas koperasi.';
      default:
        return 'Kami akan meninjau laporan Anda maksimal 1x24 jam.';
    }
  }

  static Color footerBackgroundColor(ComplaintModel complaint) {
    switch (complaint.status) {
      case 'OPEN':
        return _blueBg;
      case 'IN_PROGRESS':
        return _orangeBg;
      case 'RESOLVED':
        return _greenBg;
      case 'REJECTED':
        return _redBg;
      default:
        return _blueBg;
    }
  }

  static Color footerTextColor(ComplaintModel complaint) {
    return badgeTheme(complaint).foregroundColor;
  }

  static List<ComplaintTimelineStep> buildTimeline(ComplaintModel complaint) {
    if (complaint.status == 'REJECTED') {
      return [
        ComplaintTimelineStep(
          title: 'Ditolak',
          description: complaint.adminResponse?.trim().isNotEmpty == true
              ? complaint.adminResponse!
              : 'Komplain Anda ditolak. Silakan hubungi petugas koperasi jika ada pertanyaan.',
          timestamp: complaint.resolvedAt ?? complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.active,
          accentColor: _red,
        ),
        ComplaintTimelineStep(
          title: 'Sedang Ditinjau',
          description: 'Admin sedang memverifikasi laporan Anda.',
          timestamp: complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _orange,
        ),
        ComplaintTimelineStep(
          title: 'Komplain Dikirim',
          description: 'Laporan Anda telah berhasil dikirim.',
          timestamp: complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _blue,
        ),
      ];
    }

    if (complaint.status == 'RESOLVED') {
      return [
        ComplaintTimelineStep(
          title: 'Selesai',
          description: complaint.adminResponse?.trim().isNotEmpty == true
              ? complaint.adminResponse!
              : 'Permasalahan Anda telah diselesaikan.',
          timestamp: complaint.resolvedAt ?? complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.active,
          accentColor: _green,
        ),
        ComplaintTimelineStep(
          title: 'Disetujui',
          description: 'Komplain Anda disetujui. Silakan datang ke koperasi jika diperlukan.',
          timestamp: complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _green,
        ),
        ComplaintTimelineStep(
          title: 'Sedang Ditinjau',
          description: 'Admin sedang memverifikasi laporan Anda.',
          timestamp: complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _orange,
        ),
        ComplaintTimelineStep(
          title: 'Komplain Dikirim',
          description: 'Laporan Anda telah berhasil dikirim.',
          timestamp: complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _blue,
        ),
      ];
    }

    if (complaint.status == 'IN_PROGRESS') {
      return [
        ComplaintTimelineStep(
          title: 'Sedang Ditinjau',
          description: complaint.adminResponse?.trim().isNotEmpty == true
              ? complaint.adminResponse!
              : 'Admin sedang memverifikasi laporan Anda.',
          timestamp: complaint.respondedAt ?? complaint.createdAt,
          state: ComplaintTimelineStepState.active,
          accentColor: _orange,
        ),
        ComplaintTimelineStep(
          title: 'Komplain Dikirim',
          description: 'Laporan Anda telah berhasil dikirim.',
          timestamp: complaint.createdAt,
          state: ComplaintTimelineStepState.completed,
          accentColor: _blue,
        ),
      ];
    }

    return [
      ComplaintTimelineStep(
        title: 'Komplain Dikirim',
        description: 'Laporan Anda telah berhasil dikirim.',
        timestamp: complaint.createdAt,
        state: ComplaintTimelineStepState.active,
        accentColor: _blue,
      ),
      ComplaintTimelineStep(
        title: 'Sedang Ditinjau',
        description: 'Menunggu verifikasi dari admin.',
        timestamp: null,
          state: ComplaintTimelineStepState.pending,
        accentColor: _gray,
      ),
    ];
  }

  static Color stepDotColor(ComplaintTimelineStep step) {
    switch (step.state) {
      case ComplaintTimelineStepState.active:
        return step.accentColor;
      case ComplaintTimelineStepState.completed:
        return step.accentColor.withValues(alpha: 0.55);
      case ComplaintTimelineStepState.pending:
        return _gray;
    }
  }

  static Color stepTitleColor(ComplaintTimelineStep step) {
    switch (step.state) {
      case ComplaintTimelineStepState.active:
        return step.accentColor;
      case ComplaintTimelineStepState.completed:
        return step.accentColor.withValues(alpha: 0.85);
      case ComplaintTimelineStepState.pending:
        return _gray;
    }
  }
}
