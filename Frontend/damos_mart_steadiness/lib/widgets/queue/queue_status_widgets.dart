import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../core/utils/queue_display_utils.dart';

class QueueActiveCard extends StatelessWidget {
  const QueueActiveCard({
    super.key,
    required this.queueNumber,
    required this.remaining,
    required this.progress,
    required this.estimateMinutes,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Batalkan Antrean',
    this.isPrimaryActionLoading = false,
  });

  final String queueNumber;
  final int remaining;
  final double progress;
  final int estimateMinutes;
  final VoidCallback? onPrimaryAction;
  final String primaryActionLabel;
  final bool isPrimaryActionLoading;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QueueDisplayColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Nomor Antrean Anda',
            style: TextStyle(fontSize: 14, color: QueueDisplayColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            queueNumber,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: QueueDisplayColors.primary,
              height: 1,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa Antrean: $remaining Orang',
                style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
              ),
              Text(
                '$progressPercent% Menuju Loket',
                style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              color: QueueDisplayColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: QueueDisplayColors.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 18, color: QueueDisplayColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Estimasi Waktu Tunggu: ± $estimateMinutes Menit',
                  style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onPrimaryAction != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: isPrimaryActionLoading ? null : onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: QueueDisplayColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: QueueDisplayColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isPrimaryActionLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        primaryActionLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QueueCurrentServingCard extends StatelessWidget {
  const QueueCurrentServingCard({
    super.key,
    required this.currentServing,
  });

  final String currentServing;

  @override
  Widget build(BuildContext context) {
    final displayNumber = currentServing == 'N/A' ? '-' : currentServing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QueueDisplayColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: QueueDisplayColors.primary, size: 30),
          const SizedBox(height: 10),
          const Text(
            'Antrean Saat Ini',
            style: TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            displayNumber,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: QueueDisplayColors.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class QueueHistorySection extends StatelessWidget {
  const QueueHistorySection({
    super.key,
    required this.history,
  });

  final List<OrderModel> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Antrean',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: QueueDisplayColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QueueDisplayColors.border),
            ),
            child: const Text(
              'Belum ada riwayat antrean.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: QueueDisplayColors.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QueueDisplayColors.border),
            ),
            child: Column(
              children: List.generate(history.length, (index) {
                final order = history[index];
                final isCancelled = order.status == OrderStatus.cancelled;
                final queueNumber = order.queueNumber ?? '-';
                final statusLabel = QueueDisplayUtils.historyStatusLabel(order);
                final dateLabel = QueueDisplayUtils.formatHistoryDate(order.createdAt);

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, thickness: 1, color: QueueDisplayColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: QueueDisplayColors.cardBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCancelled ? Icons.close : Icons.check,
                              size: 20,
                              color: isCancelled ? QueueDisplayColors.hint : QueueDisplayColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  queueNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: QueueDisplayColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$dateLabel • $statusLabel',
                                  style: const TextStyle(fontSize: 12, color: QueueDisplayColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Koperasi Siswa',
                            style: TextStyle(fontSize: 12, color: QueueDisplayColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class QueuePaymentSuccessBanner extends StatelessWidget {
  const QueuePaymentSuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QueueDisplayColors.primary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: QueueDisplayColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran Berhasil! Pesanan kamu sedang diproses.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: QueueDisplayColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueEmptyCard extends StatelessWidget {
  const QueueEmptyCard({
    super.key,
    required this.onAction,
  });

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QueueDisplayColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_outlined, size: 42, color: QueueDisplayColors.hint),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Antrean Aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: QueueDisplayColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yuk pesan di katalog untuk mulai mengantre!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: QueueDisplayColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueStatusBody extends StatelessWidget {
  const QueueStatusBody({
    super.key,
    required this.queueNumber,
    required this.currentServing,
    required this.totalWaiting,
    required this.status,
    required this.history,
    this.estimateMinutes,
    this.showSuccessBanner = false,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Batalkan Antrean',
    this.isPrimaryActionLoading = false,
    this.onRefresh,
  });

  final String queueNumber;
  final String currentServing;
  final int totalWaiting;
  final QueueStatus status;
  final List<OrderModel> history;
  final int? estimateMinutes;
  final bool showSuccessBanner;
  final VoidCallback? onPrimaryAction;
  final String primaryActionLabel;
  final bool isPrimaryActionLoading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final remaining = QueueDisplayUtils.remainingPeople(
      userQueueNumber: queueNumber,
      currentServing: currentServing,
      totalWaiting: totalWaiting,
    );
    final progress = QueueDisplayUtils.queueProgress(remaining, status);
    final waitMinutes = estimateMinutes ?? (remaining * 4).clamp(5, 60);

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSuccessBanner) ...[
            const QueuePaymentSuccessBanner(),
            const SizedBox(height: 14),
          ],
          QueueActiveCard(
            queueNumber: queueNumber,
            remaining: remaining,
            progress: progress,
            estimateMinutes: waitMinutes,
            onPrimaryAction: onPrimaryAction,
            primaryActionLabel: primaryActionLabel,
            isPrimaryActionLoading: isPrimaryActionLoading,
          ),
          const SizedBox(height: 14),
          QueueCurrentServingCard(currentServing: currentServing),
          const SizedBox(height: 22),
          QueueHistorySection(history: history),
        ],
      ),
    );

    if (onRefresh == null) return content;

    return RefreshIndicator(
      color: QueueDisplayColors.primary,
      onRefresh: onRefresh!,
      child: content,
    );
  }
}
