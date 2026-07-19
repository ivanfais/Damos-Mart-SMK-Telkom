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
    this.isPreorder = false,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Batalkan Antrean',
    this.isPrimaryActionLoading = false,
  });

  final String queueNumber;
  final int remaining;
  final double progress;
  final int estimateMinutes;
  final bool isPreorder;
  final VoidCallback? onPrimaryAction;
  final String primaryActionLabel;
  final bool isPrimaryActionLoading;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: QueueDisplayColors.cardDecoration,
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
            children: [
              Expanded(
                child: Text(
                  isPreorder ? 'Status: Pre-order diproses' : 'Sisa Antrean: $remaining Orang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPreorder
                      ? 'Menunggu produksi'
                      : '$progressPercent% Menuju Loket',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
                ),
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
                Flexible(
                  child: Text(
                    'Estimasi Waktu Tunggu: ± $estimateMinutes Menit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: QueueDisplayColors.textSecondary),
                  ),
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
      decoration: QueueDisplayColors.cardDecoration,
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
            decoration: QueueDisplayColors.cardDecoration,
            child: const Text(
              'Belum ada riwayat antrean.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: QueueDisplayColors.textSecondary),
            ),
          )
        else
          Container(
            decoration: QueueDisplayColors.cardDecoration,
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
      decoration: QueueDisplayColors.cardDecoration,
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

class QueueActiveCarousel extends StatefulWidget {
  const QueueActiveCarousel({
    super.key,
    required this.queues,
    required this.currentServing,
    required this.totalWaiting,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    this.isPrimaryActionLoading = false,
  });

  final List<QueueModel> queues;
  final String currentServing;
  final int totalWaiting;
  final VoidCallback? Function(QueueModel queue) onPrimaryAction;
  final String Function(QueueModel queue) primaryActionLabel;
  final bool isPrimaryActionLoading;

  @override
  State<QueueActiveCarousel> createState() => _QueueActiveCarouselState();
}

class _QueueActiveCarouselState extends State<QueueActiveCarousel> {
  static const Duration _slideDuration = Duration(milliseconds: 300);
  static const Curve _slideCurve = Curves.easeInOut;
  static const double _cardViewportHeight = 326;

  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant QueueActiveCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.queues.length) {
      _currentIndex = widget.queues.isEmpty ? 0 : widget.queues.length - 1;
      if (widget.queues.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.queues.length) return;
    _pageController.animateToPage(
      index,
      duration: _slideDuration,
      curve: _slideCurve,
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: enabled ? 0.95 : 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: QueueDisplayColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? QueueDisplayColors.primary : QueueDisplayColors.hint,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselPage(QueueModel queue) {
    return _ActiveQueueCard(
      queue: queue,
      currentServing: widget.currentServing,
      totalWaiting: widget.totalWaiting,
      onPrimaryAction: widget.onPrimaryAction(queue),
      primaryActionLabel: widget.primaryActionLabel(queue),
      isPrimaryActionLoading: widget.isPrimaryActionLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final queues = widget.queues;
    if (queues.isEmpty) return const SizedBox.shrink();

    if (queues.length == 1) {
      return _buildCarouselPage(queues.first);
    }

    final canGoBack = _currentIndex > 0;
    final canGoForward = _currentIndex < queues.length - 1;

    return Column(
      children: [
        SizedBox(
          height: _cardViewportHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: queues.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) => _buildCarouselPage(queues[index]),
              ),
              if (canGoBack)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _navButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: true,
                      onTap: () => _goToPage(_currentIndex - 1),
                    ),
                  ),
                ),
              if (canGoForward)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _navButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: true,
                      onTap: () => _goToPage(_currentIndex + 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(queues.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: _slideDuration,
              curve: _slideCurve,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? QueueDisplayColors.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class QueueListBody extends StatelessWidget {
  const QueueListBody({
    super.key,
    this.activeQueues = const [],
    required this.currentServing,
    required this.totalWaiting,
    required this.history,
    this.onEmptyAction,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    this.isPrimaryActionLoading = false,
    this.onRefresh,
  });

  final List<QueueModel> activeQueues;
  final String currentServing;
  final int totalWaiting;
  final List<OrderModel> history;
  final VoidCallback? onEmptyAction;
  final VoidCallback? Function(QueueModel queue) onPrimaryAction;
  final String Function(QueueModel queue) primaryActionLabel;
  final bool isPrimaryActionLoading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeQueues.isNotEmpty)
            QueueActiveCarousel(
              queues: activeQueues,
              currentServing: currentServing,
              totalWaiting: totalWaiting,
              onPrimaryAction: onPrimaryAction,
              primaryActionLabel: primaryActionLabel,
              isPrimaryActionLoading: isPrimaryActionLoading,
            )
          else
            QueueEmptyCard(onAction: onEmptyAction ?? () {}),
          const SizedBox(height: 14),
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

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({
    required this.queue,
    required this.currentServing,
    required this.totalWaiting,
    this.onPrimaryAction,
    this.primaryActionLabel = 'QR Pengambilan',
    this.isPrimaryActionLoading = false,
  });

  final QueueModel queue;
  final String currentServing;
  final int totalWaiting;
  final VoidCallback? onPrimaryAction;
  final String primaryActionLabel;
  final bool isPrimaryActionLoading;

  @override
  Widget build(BuildContext context) {
    final isPreorder = QueueDisplayUtils.isPreorderQueue(queue);
    final remaining = isPreorder
        ? 0
        : QueueDisplayUtils.remainingPeople(
            userQueueNumber: queue.queueNumber,
            currentServing: currentServing,
            totalWaiting: totalWaiting,
          );
    final progress = isPreorder
        ? (queue.status == QueueStatus.ready ? 1.0 : 0.35)
        : QueueDisplayUtils.queueProgress(remaining, queue.status);
    final waitMinutes = queue.estimatedWaitMinutes ?? (remaining * 4).clamp(5, 60);

    return QueueActiveCard(
      queueNumber: queue.queueNumber,
      remaining: remaining,
      progress: progress,
      estimateMinutes: waitMinutes,
      isPreorder: isPreorder,
      onPrimaryAction: onPrimaryAction,
      primaryActionLabel: primaryActionLabel,
      isPrimaryActionLoading: isPrimaryActionLoading,
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
