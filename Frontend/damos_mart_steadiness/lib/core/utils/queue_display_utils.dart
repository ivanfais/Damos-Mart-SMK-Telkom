import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/order/order_cubit.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import 'relative_date_utils.dart';

class QueueDisplayColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF3F4F6);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class QueueDisplayUtils {
  QueueDisplayUtils._();

  static bool hasCurrentServing(String currentServing) {
    final trimmed = currentServing.trim();
    return trimmed.isNotEmpty && trimmed != 'N/A' && trimmed != '-';
  }

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

    // Pre-order / produksi: tetap aktif sampai selesai diambil (bukan antrean loket harian).
    if (order != null &&
        (order.isPreorder || order.status == OrderStatus.inProduction)) {
      return true;
    }

    if (isQueueTurnPassed(
      userQueueNumber: queue.queueNumber,
      currentServing: currentServing,
    )) {
      return false;
    }

    return true;
  }

  /// Daftar antrean aktif terurut nomor antrean (sama seperti board admin).
  static List<QueueModel> sortedActiveQueues(List<QueueModel> activeQueues) {
    final candidates = activeQueues
        .where(
          (queue) =>
              queue.status == QueueStatus.waiting ||
              queue.status == QueueStatus.preparing ||
              queue.status == QueueStatus.ready,
        )
        .toList();
    candidates.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
    return candidates;
  }

  /// Antrean utama yang ditampilkan di tab Antrean / beranda.
  static QueueModel? pickPrimaryQueue(List<QueueModel> activeQueues) {
    final sorted = sortedActiveQueues(activeQueues);
    return sorted.isEmpty ? null : sorted.first;
  }

  static bool isPreorderQueue(QueueModel queue) {
    final order = queue.order;
    return order != null &&
        (order.isPreorder || order.status == OrderStatus.inProduction);
  }

  /// Selaras filter board admin untuk siswa.
  static bool isVisibleOnStudentBoard(QueueModel queue, String userId) {
    if (userId.isEmpty || queue.userId != userId) return false;
    if (queue.status == QueueStatus.completed || queue.status == QueueStatus.skipped) {
      return false;
    }

    final order = queue.order;
    if (order == null) return false;
    if (order.status == OrderStatus.completed || order.status == OrderStatus.cancelled) {
      return false;
    }
    if (order.paymentStatus == PaymentStatus.unpaid &&
        order.paymentMethod == PaymentMethod.qris) {
      return false;
    }

    return queue.status == QueueStatus.waiting ||
        queue.status == QueueStatus.preparing ||
        queue.status == QueueStatus.ready;
  }

  /// Hanya antrean milik user yang sedang login; duplikat & data tidak valid diabaikan.
  static List<QueueModel> queuesForUser(List<QueueModel> queues, String userId) {
    if (userId.isEmpty) return const [];

    final seenIds = <String>{};
    final result = <QueueModel>[];

    for (final queue in queues) {
      if (!isVisibleOnStudentBoard(queue, userId)) continue;
      if (!seenIds.add(queue.id)) continue;
      result.add(queue);
    }

    return result;
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
    final local = dateTime.toLocal();
    final diffDays = RelativeDateUtils.daysAgo(local);
    final time = DateFormat('HH:mm', 'id_ID').format(local);

    if (diffDays == 0) {
      return 'Hari ini, $time';
    }
    if (diffDays == 1) {
      return 'Kemarin, $time';
    }
    if (diffDays < 7) {
      return '$diffDays hari lalu, $time';
    }
    return DateFormat('dd MMM, HH:mm', 'id_ID').format(local);
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
    String? userId,
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
      if (userId != null && queue.userId != userId) continue;
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
