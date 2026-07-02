import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/order/order_cubit.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';

class QueueDisplayColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF3F4F6);
}

class QueueDisplayUtils {
  QueueDisplayUtils._();

  static int? queueSequence(String number) {
    final match = RegExp(r'(\d+)$').firstMatch(number.trim());
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int remainingPeople({
    required String userQueueNumber,
    required String currentServing,
    required int totalWaiting,
  }) {
    final userSeq = queueSequence(userQueueNumber);
    final currentSeq = queueSequence(currentServing);
    if (userSeq == null || currentSeq == null || currentServing == 'N/A') {
      return totalWaiting;
    }
    return (userSeq - currentSeq).clamp(0, 99);
  }

  /// Sama seperti influence: nomor user sudah dilampaui antrean saat ini.
  static bool isQueueTurnPassed({
    required String userQueueNumber,
    required String currentServing,
  }) {
    final userSeq = queueSequence(userQueueNumber);
    final currentSeq = queueSequence(currentServing);
    if (userSeq == null || currentSeq == null || currentServing == 'N/A') {
      return false;
    }
    return userSeq < currentSeq;
  }

  static bool shouldShowInActive({
    required QueueModel queue,
    required String currentServing,
  }) {
    if (queue.status == QueueStatus.completed || queue.status == QueueStatus.skipped) {
      return false;
    }

    final order = queue.order;
    if (order != null &&
        (order.status == OrderStatus.completed || order.status == OrderStatus.cancelled)) {
      return false;
    }

    if (isQueueTurnPassed(
      userQueueNumber: queue.queueNumber,
      currentServing: currentServing,
    )) {
      return false;
    }

    return true;
  }

  static double queueProgress(int remaining, QueueStatus status) {
    if (status == QueueStatus.ready || status == QueueStatus.completed) {
      return 1.0;
    }
    if (remaining == 0) return 0.85;
    final total = remaining + 3;
    return ((total - remaining) / total).clamp(0.15, 0.85);
  }

  static String formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat('HH:mm', 'id_ID').format(dateTime);

    if (target == today) {
      return 'Hari ini, $time';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Kemarin, $time';
    }
    return DateFormat('dd MMM, HH:mm', 'id_ID').format(dateTime);
  }

  static String historyStatusLabel(OrderModel order) {
    if (order.status == OrderStatus.cancelled) return 'Dibatalkan';
    if (order.status == OrderStatus.completed) return 'Selesai';
    final queueStatus = order.queueStatus?.toUpperCase();
    if (queueStatus == 'SKIPPED') return 'Terlewat';
    if (queueStatus == 'COMPLETED') return 'Selesai';
    return 'Selesai';
  }

  static List<OrderModel> historyOrders(OrderState orderState) {
    if (orderState is! OrderHistoryLoaded) return [];
    return historyOrdersFromList(orderState.orders);
  }

  static List<OrderModel> historyOrdersFromList(
    List<OrderModel> orders, {
    List<QueueModel> passedQueues = const [],
  }) {
    final history = orders.where((order) {
      if (order.queueNumber == null || order.queueNumber!.isEmpty) return false;

      if (order.status == OrderStatus.completed || order.status == OrderStatus.cancelled) {
        return true;
      }

      final queueStatus = order.queueStatus?.toUpperCase();
      if (queueStatus == 'COMPLETED' || queueStatus == 'SKIPPED') {
        return true;
      }

      return false;
    }).toList();

    final seenIds = history.map((order) => order.id).toSet();
    for (final queue in passedQueues) {
      final order = queue.order;
      if (order == null || seenIds.contains(order.id)) continue;
      if (order.queueNumber == null || order.queueNumber!.isEmpty) continue;
      history.add(order);
      seenIds.add(order.id);
    }

    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return history.take(10).toList();
  }
}
