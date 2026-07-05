import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import 'relative_date_utils.dart';

enum NotificationTimeGroup { today, yesterday, thisWeek, lastWeek, older }

class NotificationDisplayColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color iconBg = Color(0xFFF3F4F6);
  static const Color tagBg = Color(0xFFF3F4F6);
}

class NotificationDisplayUtils {
  NotificationDisplayUtils._();

  static NotificationTimeGroup timeGroup(DateTime date) {
    final now = DateTime.now();
    final diffDays = RelativeDateUtils.daysAgo(date);

    if (diffDays == 0) return NotificationTimeGroup.today;
    if (diffDays == 1) return NotificationTimeGroup.yesterday;
    if (RelativeDateUtils.isSameCalendarWeek(date, now)) {
      return NotificationTimeGroup.thisWeek;
    }
    if (RelativeDateUtils.isPreviousCalendarWeek(date, now)) {
      return NotificationTimeGroup.lastWeek;
    }
    return NotificationTimeGroup.older;
  }

  static String? groupTitle(NotificationTimeGroup group) {
    switch (group) {
      case NotificationTimeGroup.today:
        return 'Hari Ini';
      case NotificationTimeGroup.yesterday:
        return 'Kemarin';
      case NotificationTimeGroup.thisWeek:
        return 'Minggu Ini';
      case NotificationTimeGroup.lastWeek:
        return 'Minggu Lalu';
      case NotificationTimeGroup.older:
        return 'Lainnya';
    }
  }

  static List<NotificationTimeGroup> visibleGroups = const [
    NotificationTimeGroup.today,
    NotificationTimeGroup.yesterday,
    NotificationTimeGroup.thisWeek,
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
        return 'Informasi';
    }
  }

  static IconData iconFor(NotificationModel notification) {
    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();

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
    if (notification.type == NotificationType.complaint ||
        title.contains('komplain')) {
      return Icons.support_agent_outlined;
    }
    return Icons.info_outline;
  }

  static String timeLabel(DateTime createdAt) {
    final local = createdAt.toLocal();
    final diffDays = RelativeDateUtils.daysAgo(local);

    if (diffDays == 0) {
      return DateFormat('HH:mm').format(local);
    }
    if (diffDays == 1) return 'Kemarin';
    if (diffDays < 7) return '$diffDays hari lalu';
    return DateFormat('dd MMM', 'id_ID').format(local);
  }
}
