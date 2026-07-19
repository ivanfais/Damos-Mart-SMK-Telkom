import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/queue_repository.dart';

class NotificationNavigation {
  NotificationNavigation._();

  static bool isHistoryRelated(NotificationModel notification) {
    return notification.type == NotificationType.complaint ||
        notification.type == NotificationType.queueReady ||
        notification.type == NotificationType.orderStatus;
  }

  static bool hasHistoryUnread(List<NotificationModel> notifications) {
    return latestUnread(notifications, isHistoryRelated) != null;
  }

  static NotificationModel? latestUnread(
    List<NotificationModel> notifications,
    bool Function(NotificationModel notification) where,
  ) {
    final matches = notifications.where((n) => !n.isRead).where(where).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (matches.isEmpty) return null;
    return matches.first;
  }

  static List<NotificationModel> unreadHistoryNotifications(
    List<NotificationModel> notifications,
    bool Function(NotificationModel notification) where,
  ) {
    return notifications.where((n) => !n.isRead).where(where).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Returns true when navigation to a detail screen succeeded.
  static Future<bool> navigate(
    BuildContext context,
    NotificationModel notification, {
    bool silent = false,
  }) async {
    final ref = notification.referenceId;

    switch (notification.type) {
      case NotificationType.complaint:
        if (ref != null && ref.isNotEmpty) {
          final exists = await _complaintExists(ref);
          if (!context.mounted) return false;
          if (exists) {
            context.push('/complaints/$ref');
            return true;
          }
          if (!silent) _showStaleNotice(context);
          return false;
        }
        return false;
      case NotificationType.queueReady:
      case NotificationType.orderStatus:
        if (ref != null && ref.isNotEmpty) {
          final orderId = await _resolveOrderId(ref);
          if (!context.mounted) return false;
          if (orderId != null) {
            context.read<OrderCubit>().loadOrderDetail(orderId);
            context.push('/orders/$orderId');
            return true;
          }
          if (!silent) _showStaleNotice(context);
          return false;
        }
        if (notification.type == NotificationType.queueReady) {
          context.go('/history?tab=ready');
        } else {
          context.go('/history');
        }
        return true;
      case NotificationType.chat:
        context.push('/profile/chat');
        return true;
      case NotificationType.promo:
        context.go('/home');
        return true;
    }
  }

  /// Tries unread notifications newest-first. Stale ones are marked read silently.
  /// Returns true when a detail screen was opened.
  static Future<bool> openLatestUnread(
    BuildContext context, {
    required bool Function(NotificationModel notification) where,
  }) async {
    final cubit = context.read<NotificationCubit>();
    var current = cubit.state;

    if (current is! NotificationLoaded) {
      await cubit.loadNotifications(showLoading: false);
      current = cubit.state;
    }
    if (current is! NotificationLoaded) return false;

    final unreadList = unreadHistoryNotifications(current.notifications, where);
    if (unreadList.isEmpty) return false;

    for (final notification in unreadList) {
      if (!notification.isRead) {
        await cubit.markAsRead(notification.id);
      }
      if (!context.mounted) return false;

      final navigated = await navigate(context, notification, silent: true);
      if (navigated) return true;
    }

    return false;
  }

  static Future<String?> _resolveOrderId(String ref) async {
    if (await _orderExists(ref)) return ref;

    // Legacy QUEUE_READY notifications may store queue id instead of order id.
    try {
      final queue = await QueueRepository().getQueueDetails(ref);
      if (await _orderExists(queue.orderId)) return queue.orderId;
    } catch (_) {}

    return null;
  }

  static Future<bool> _orderExists(String orderId) async {
    try {
      await OrderRepository().getOrderDetails(orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _complaintExists(String complaintId) async {
    try {
      final complaint =
          await ComplaintRepository().findComplaintById(complaintId);
      return complaint != null;
    } catch (_) {
      return false;
    }
  }

  static void _showStaleNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pesanan/komplain tidak ditemukan. Data mungkin sudah dihapus.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
