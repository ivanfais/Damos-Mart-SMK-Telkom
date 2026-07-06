import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../theme/damos_dominance_colors.dart';

enum NotificationTimeGroup { today, yesterday, lastWeek, older }

class NotificationDisplayUtils {
  NotificationDisplayUtils._();

  static NotificationTimeGroup timeGroup(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return NotificationTimeGroup.today;
    if (diffDays == 1) return NotificationTimeGroup.yesterday;
    if (diffDays < 7) return NotificationTimeGroup.lastWeek;
    return NotificationTimeGroup.older;
  }

  static String? groupTitle(NotificationTimeGroup group) {
    switch (group) {
      case NotificationTimeGroup.today:
        return 'Hari Ini';
      case NotificationTimeGroup.yesterday:
        return 'Kemarin';
      case NotificationTimeGroup.lastWeek:
        return 'Minggu Lalu';
      case NotificationTimeGroup.older:
        return 'Lainnya';
    }
  }

  static const visibleGroups = [
    NotificationTimeGroup.today,
    NotificationTimeGroup.yesterday,
    NotificationTimeGroup.lastWeek,
    NotificationTimeGroup.older,
  ];

  static Map<NotificationTimeGroup, List<NotificationModel>> groupNotifications(
    List<NotificationModel> notifications,
  ) {
    final sorted = [...notifications]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final grouped = <NotificationTimeGroup, List<NotificationModel>>{};

    for (final notification in sorted) {
      final group = timeGroup(notification.createdAt);
      grouped.putIfAbsent(group, () => []).add(notification);
    }

    return grouped;
  }

  static String categoryLabel(NotificationType type) {
    switch (type) {
      case NotificationType.queueReady:
        return 'Antrean';
      case NotificationType.orderStatus:
        return 'Pesanan';
      case NotificationType.complaint:
        return 'Komplain';
      case NotificationType.promo:
      case NotificationType.chat:
        return 'Lainnya';
    }
  }

  static IconData iconFor(NotificationModel notification) {
    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();

    if (notification.type == NotificationType.complaint ||
        title.contains('komplain') ||
        body.contains('komplain')) {
      return Icons.report_problem_outlined;
    }
    if (notification.type == NotificationType.queueReady ||
        title.contains('antrean') ||
        body.contains('antrean')) {
      return Icons.hourglass_empty_outlined;
    }
    if (title.contains('pembayaran') || title.contains('berhasil')) {
      return Icons.shopping_bag_outlined;
    }
    if (title.contains('siap') || title.contains('diambil') || body.contains('diambil')) {
      return Icons.local_shipping_outlined;
    }
    if (notification.type == NotificationType.promo ||
        title.contains('stok') ||
        title.contains('katalog')) {
      return Icons.campaign_outlined;
    }
    if (notification.type == NotificationType.chat) {
      return Icons.chat_bubble_outline;
    }
    return Icons.info_outline;
  }

  static Color iconBackgroundFor(NotificationModel notification) {
    if (notification.type == NotificationType.complaint) {
      return const Color(0xFFFFF3E0);
    }
    return DamosDominanceColors.primary.withValues(alpha: 0.12);
  }

  static String timeLabel(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      return DateFormat('HH:mm').format(local);
    }
    if (diffDays == 1) return 'Kemarin';
    if (diffDays < 7) return '$diffDays hari lalu';
    return DateFormat('dd MMM').format(local);
  }
}
