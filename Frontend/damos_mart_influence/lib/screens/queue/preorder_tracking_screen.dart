import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../config/api_config.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color bgGrey = Color(0xFFF2F2F2);
}

class _TimelineStep {
  final String title;
  final String subtitle;

  const _TimelineStep({required this.title, required this.subtitle});
}

class PreorderTrackingScreen extends StatefulWidget {
  final String queueId;

  const PreorderTrackingScreen({super.key, required this.queueId});

  @override
  State<PreorderTrackingScreen> createState() => _PreorderTrackingScreenState();
}

class _PreorderTrackingScreenState extends State<PreorderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadQueueDetail(widget.queueId);
  }

  int _activeStepIndex(OrderStatus status, PaymentStatus paymentStatus) {
    if (status == OrderStatus.completed) return 3;
    if (status == OrderStatus.ready) return 2;
    if (status == OrderStatus.inProduction || status == OrderStatus.preparing) return 1;
    if (status == OrderStatus.paid || paymentStatus == PaymentStatus.paid) return 1;
    return 0;
  }

  DateTime _addBusinessDays(DateTime start, int days) {
    var result = start;
    var added = 0;
    while (added < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        added++;
      }
    }
    return result;
  }

  String _productTitle(OrderModel order) {
    if (order.orderItems.isNotEmpty) {
      return order.orderItems.first.productName;
    }
    return 'Pre-Order Seragam';
  }

  String? _productImage(OrderModel order) {
    // Order items may not include image URL; return null for placeholder.
    return null;
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final productName = _productTitle(order);
    final orderId = order.orderNumber.startsWith('#') ? order.orderNumber : '#${order.orderNumber}';
    final orderDate = DateFormatter.formatShort(order.paidAt ?? order.createdAt);
    final imageUrl = _productImage(order);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(imageUrl),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.checkroom_outlined, color: _Ds.hint, size: 28),
                    )
                  : const Icon(Icons.checkroom_outlined, color: _Ds.hint, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _Ds.textPrimary, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order ID: $orderId',
                  style: const TextStyle(fontSize: 12, color: _Ds.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order Date: $orderDate',
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final activeIndex = _activeStepIndex(order.status, order.paymentStatus);
    final paidDate = order.paidAt ?? order.createdAt;

    final steps = [
      _TimelineStep(
        title: 'Pesanan Dibayar',
        subtitle: '${DateFormatter.formatShort(paidDate)}, ${DateFormatter.formatTimeOnly(paidDate)}',
      ),
      const _TimelineStep(
        title: 'Dalam Produksi',
        subtitle: 'Sedang dalam proses penjahitan masal di vendor.',
      ),
      const _TimelineStep(
        title: 'Siap Diambil',
        subtitle: 'Menunggu penyelesaian produksi.',
      ),
      const _TimelineStep(
        title: 'Selesai',
        subtitle: '',
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        final isDone = isCompleted || isActive;

        final dotColor = isDone ? _Ds.primary : _Ds.borderLight;
        final lineColor = !isLast && index <= activeIndex ? _Ds.primary : _Ds.borderLight;

        final titleStyle = TextStyle(
          fontSize: 15,
          fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
          color: isDone ? _Ds.textPrimary : _Ds.hint,
        );

        final subtitleStyle = TextStyle(
          fontSize: 13,
          color: isDone ? _Ds.textSecondary : _Ds.hint,
          height: 1.4,
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: lineColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: titleStyle),
                      if (step.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(step.subtitle, style: subtitleStyle),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEstimateCard(OrderModel order) {
    final baseDate = order.paidAt ?? order.createdAt;
    final estimateDate = _addBusinessDays(baseDate, 14);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 28, color: _Ds.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimasi Siap Diambil', style: TextStyle(fontSize: 13, color: _Ds.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatShort(estimateDate),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Ds.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: _Ds.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Informasi: Proses produksi memakan waktu maksimal 14 hari kerja sejak pembayaran dikonfirmasi.',
              style: TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          LoadingShimmer(width: double.infinity, height: 84, borderRadius: 12),
          SizedBox(height: 28),
          LoadingShimmer(width: 160, height: 22, borderRadius: 8),
          SizedBox(height: 20),
          LoadingShimmer(width: double.infinity, height: 220, borderRadius: 12),
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
            title: 'Status Antrean Pre-Order',
            showBackButton: true,
            backgroundColor: Colors.white,
            foregroundColor: _Ds.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<QueueCubit, QueueState>(
        builder: (context, state) {
          if (state is QueueLoading) {
            return _buildScrollPage(_buildShimmerLoading());
          }

          if (state is QueueError) {
            return _buildScrollPage(
              ErrorState(
                message: state.message,
                onRetry: () => context.read<QueueCubit>().loadQueueDetail(widget.queueId),
              ),
            );
          }

          if (state is QueueDetailLoaded) {
            final order = state.queue.order;

            if (order == null) {
              return _buildScrollPage(
                ErrorState(
                  message: 'Data pesanan tidak ditemukan.',
                  onRetry: () => context.read<QueueCubit>().loadQueueDetail(widget.queueId),
                ),
              );
            }

            return _buildScrollPage(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOrderInfoCard(order),
                  const SizedBox(height: 28),
                  const Text(
                    'Progres Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeline(order),
                  const SizedBox(height: 24),
                  _buildEstimateCard(order),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/queue/${widget.queueId}/qr'),
                      icon: const Icon(Icons.qr_code, size: 20),
                      label: const Text('Lihat Tiket QR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Ds.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.push('/profile/chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Ds.textPrimary,
                        side: const BorderSide(color: _Ds.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Hubungi Admin Koperasi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoNotice(),
                ],
              ),
            );
          }

          return const Center(child: Text('Memuat pelacakan pre-order...'));
        },
      ),
    );
  }
}
