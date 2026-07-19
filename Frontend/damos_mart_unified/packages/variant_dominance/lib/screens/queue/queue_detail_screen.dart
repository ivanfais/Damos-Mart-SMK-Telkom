import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../core/socket/socket_service.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/queue_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class _Ds {
  static const Color green = Color(0xFF1B8C2E);
  static const Color red = Color(0xFFD42427);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFBFC5CE);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color progressFill = Color(0xFF0D3B66);
  static const Color progressEmpty = Color(0xFFE0E0E0);
}

class QueueDetailScreen extends StatefulWidget {
  final String queueId;

  const QueueDetailScreen({super.key, required this.queueId});

  @override
  State<QueueDetailScreen> createState() => _QueueDetailScreenState();
}

class _QueueDetailScreenState extends State<QueueDetailScreen> {
  String _currentServing = 'N/A';
  int _totalWaiting = 0;

  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadQueueDetail(widget.queueId);
    _loadQueueStats();

    SocketService.instance.onQueueUpdated(_handleSocketUpdate);
    SocketService.instance.onQueueCalled(_handleSocketUpdate);
    SocketService.instance.onQueueReady(_handleSocketUpdate);
  }

  void _handleSocketUpdate(dynamic data) {
    if (data != null && data['queueId'] == widget.queueId && mounted) {
      context.read<QueueCubit>().updateQueueDetailSilently(widget.queueId);
      _loadQueueStats();
    }
  }

  Future<void> _loadQueueStats() async {
    try {
      final stats = await QueueRepository().getCurrentQueueState();
      if (!mounted) return;
      setState(() {
        _currentServing = stats['currentServing']?.toString() ?? 'N/A';
        _totalWaiting = stats['totalWaiting'] as int? ?? 0;
      });
    } catch (_) {}
  }

  int? _queueSequence(String number) {
    final match = RegExp(r'(\d+)$').firstMatch(number.trim());
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String _queuePrefix(String number) {
    final idx = number.lastIndexOf('-');
    return idx > 0 ? number.substring(0, idx) : 'A';
  }

  String _formatQueueNumber(String prefix, int seq, String reference) {
    final refMatch = RegExp(r'-(\d+)$').firstMatch(reference);
    final pad = refMatch?.group(1)?.length ?? 3;
    return '$prefix-${seq.toString().padLeft(pad, '0')}';
  }

  ({double progress, int remaining}) _queueProgress(String userNumber, QueueStatus status) {
    if (status == QueueStatus.ready || status == QueueStatus.completed) {
      return (progress: 1.0, remaining: 0);
    }

    final userSeq = _queueSequence(userNumber);
    final currentSeq = _queueSequence(_currentServing);

    if (userSeq == null || currentSeq == null || _currentServing == 'N/A') {
      return (progress: 0.35, remaining: _totalWaiting);
    }

    final remaining = (userSeq - currentSeq).clamp(0, 99);
    if (remaining == 0) return (progress: 0.85, remaining: 0);

    final total = remaining + 3;
    final progress = ((total - remaining) / total).clamp(0.15, 0.85);
    return (progress: progress, remaining: remaining);
  }

  ({String title, String subtitle, IconData icon}) _statusInfo(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return (
          title: 'Status Pesanan',
          subtitle: 'Menunggu Antrean',
          icon: Icons.hourglass_top_outlined,
        );
      case QueueStatus.preparing:
        return (
          title: 'Status Pesanan',
          subtitle: 'Pesanan Sedang Disiapkan',
          icon: Icons.restaurant,
        );
      case QueueStatus.ready:
        return (
          title: 'Status Pesanan',
          subtitle: 'Siap Diambil',
          icon: Icons.check_circle_outline,
        );
      case QueueStatus.completed:
        return (
          title: 'Status Pesanan',
          subtitle: 'Pesanan Selesai',
          icon: Icons.task_alt,
        );
      case QueueStatus.skipped:
        return (
          title: 'Status Pesanan',
          subtitle: 'Antrean Terlewat',
          icon: Icons.warning_amber_outlined,
        );
    }
  }

  String _productCountLabel(QueueModel queue) {
    final total = queue.order?.orderItems.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
    return '$total Barang';
  }

  String _waitEstimate(QueueModel queue) {
    if (queue.estimatedWaitMinutes != null && queue.status == QueueStatus.waiting) {
      return '${queue.estimatedWaitMinutes} Menit';
    }
    return '10-15 Menit';
  }

  List<({String number, String status, bool highlight})> _nearbyQueueItems(String userNumber) {
    final prefix = _queuePrefix(userNumber);
    final currentSeq = _queueSequence(_currentServing) ?? _queueSequence(userNumber) ?? 1;

    String statusFor(int seq) {
      if (_currentServing != 'N/A') {
        final servingSeq = _queueSequence(_currentServing);
        if (servingSeq != null) {
          if (seq < servingSeq) return 'Selesai';
          if (seq == servingSeq) return 'Di Loket';
          return 'Menunggu';
        }
      }
      if (seq < currentSeq) return 'Selesai';
      if (seq == currentSeq) return 'Di Loket';
      return 'Menunggu';
    }

    final sequences = [currentSeq - 1, currentSeq, currentSeq + 1].where((s) => s > 0).toList();
    if (sequences.length < 3 && currentSeq > 1) {
      sequences.insert(0, currentSeq - 1);
    }

    return sequences.take(3).map((seq) {
      final number = _formatQueueNumber(prefix, seq, userNumber);
      final status = statusFor(seq);
      final highlight = status == 'Di Loket' || number == userNumber;
      return (number: number, status: status, highlight: highlight);
    }).toList();
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: _Ds.green,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 12,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/queue');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Text(
            'Damos Mart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(QueueStatus status) {
    final info = _statusInfo(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _Ds.green,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(info.icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueNumberCard(QueueModel queue) {
    final progressData = _queueProgress(queue.queueNumber, queue.status);
    final filledFlex = (progressData.progress * 100).round().clamp(5, 95);
    final emptyFlex = 100 - filledFlex;
    final servingLabel = _currentServing == 'N/A' ? '-' : _currentServing;
    final remainingLabel = progressData.remaining <= 0 ? 'Antrean Anda' : 'Sisa ${progressData.remaining} Antrean';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          const Text(
            'Nomor Antrean Anda',
            style: TextStyle(
              fontSize: 14,
              color: _Ds.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            queue.queueNumber,
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              color: _Ds.red,
              height: 1.1,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: filledFlex,
                    child: Container(color: _Ds.progressFill),
                  ),
                  Expanded(
                    flex: emptyFlex,
                    child: Container(color: _Ds.progressEmpty),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sekarang: $servingLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _Ds.textPrimary,
                ),
              ),
              Text(
                remainingLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: _Ds.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _Ds.textSecondary),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _Ds.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsRow(QueueModel queue) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_outlined,
            label: 'Estimasi Tunggu',
            value: _waitEstimate(queue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.inventory_2_outlined,
            label: 'Total Produk',
            value: _productCountLabel(queue),
          ),
        ),
      ],
    );
  }

  Widget _buildLihatTiketButton(QueueModel queue) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => context.push('/queue/${queue.id}/qr'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 20),
            SizedBox(width: 8),
            Text(
              'Lihat Tiket QR',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubungiAdminButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => context.push('/profile/chat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _Ds.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Hubungi Admin Koperasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildQueueItem({
    required String number,
    required String status,
    required bool highlight,
  }) {
    final dotColor = highlight ? _Ds.textPrimary : _Ds.textHint;
    final textColor = highlight ? _Ds.textPrimary : _Ds.textHint;
    final fontWeight = highlight ? FontWeight.w700 : FontWeight.w400;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 14),
        Text(
          '$number - $status',
          style: TextStyle(
            fontSize: 15,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueListCard(String userNumber) {
    final items = _nearbyQueueItems(userNumber);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANTREAN DAMOS MART',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _Ds.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
              child: _buildQueueItem(
                number: item.number,
                status: item.status,
                highlight: item.highlight,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(QueueModel queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _buildStatusBanner(queue.status),
          const SizedBox(height: 20),
          _buildQueueNumberCard(queue),
          const SizedBox(height: 16),
          _buildInfoCardsRow(queue),
          const SizedBox(height: 16),
          _buildLihatTiketButton(queue),
          const SizedBox(height: 10),
          _buildHubungiAdminButton(),
          const SizedBox(height: 24),
          _buildQueueListCard(queue.queueNumber),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: const [
          LoadingShimmer(width: double.infinity, height: 76, borderRadius: 14),
          SizedBox(height: 20),
          LoadingShimmer(width: double.infinity, height: 200, borderRadius: 16),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingShimmer(width: double.infinity, height: 110, borderRadius: 14)),
              SizedBox(width: 12),
              Expanded(child: LoadingShimmer(width: double.infinity, height: 110, borderRadius: 14)),
            ],
          ),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 50, borderRadius: 12),
          SizedBox(height: 10),
          LoadingShimmer(width: double.infinity, height: 50, borderRadius: 12),
          SizedBox(height: 24),
          LoadingShimmer(width: double.infinity, height: 160, borderRadius: 14),
        ],
      ),
    );
  }

  Widget _buildScrollPage(List<Widget> children) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppBar(context),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocBuilder<QueueCubit, QueueState>(
        builder: (context, state) {
          if (state is QueueLoading) {
            return _buildScrollPage([_buildShimmerLoading()]);
          }

          if (state is QueueError) {
            return _buildScrollPage([
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<QueueCubit>().loadQueueDetail(widget.queueId),
                ),
              ),
            ]);
          }

          if (state is QueueDetailLoaded) {
            return _buildScrollPage([_buildContent(state.queue)]);
          }

          return _buildScrollPage([
            const SizedBox(
              height: 240,
              child: Center(child: Text('Memuat detail antrean...')),
            ),
          ]);
        },
      ),
    );
  }
}
