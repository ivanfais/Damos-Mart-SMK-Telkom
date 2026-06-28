import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/queue_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color red = Color(0xFFD42427);
  static const Color borderLight = Color(0xFFE5E7EB);
}

class OrderCompleteScreen extends StatefulWidget {
  final String queueId;

  const OrderCompleteScreen({super.key, required this.queueId});

  @override
  State<OrderCompleteScreen> createState() => _OrderCompleteScreenState();
}

class _OrderCompleteScreenState extends State<OrderCompleteScreen> {
  final QueueRepository _repository = QueueRepository();
  QueueModel? _queue;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queue = await _repository.getQueueDetails(widget.queueId);
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
        ),
      ],
    );
  }

  Widget _buildInfoCard(QueueModel queue) {
    final pickupTime = queue.completedAt ?? queue.updatedAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Nomor Antrean',
            queue.queueNumber,
            valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Ds.red),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Waktu Pengambilan',
            DateFormatter.formatWeekdayTime(pickupTime),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(QueueModel queue) {
    final order = queue.order;
    final hasReviewTarget = order != null && order.orderItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: _Ds.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pesanan Telah Diambil',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Terima kasih telah berbelanja di Damos Mart',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(queue),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (hasReviewTarget) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  final firstItem = order!.orderItems.first;
                  context.push('/review/${order.id}/${firstItem.productId}');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Ds.primary,
                  side: const BorderSide(color: _Ds.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Beri Rating Produk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollPage(Widget child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosPageHeader(
            title: 'Damos Mart',
            showBackButton: true,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          LoadingShimmer(width: 80, height: 80, borderRadius: 40),
          SizedBox(height: 20),
          LoadingShimmer(width: 240, height: 28, borderRadius: 8),
          SizedBox(height: 8),
          LoadingShimmer(width: 260, height: 14, borderRadius: 6),
          SizedBox(height: 32),
          LoadingShimmer(width: double.infinity, height: 90, borderRadius: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildScrollPage(
        _isLoading
            ? _buildShimmerLoading()
            : _errorMessage != null
                ? SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.55,
                    child: ErrorState(
                      message: _errorMessage!,
                      onRetry: _loadQueue,
                    ),
                  )
                : _buildContent(_queue!),
      ),
    );
  }
}
