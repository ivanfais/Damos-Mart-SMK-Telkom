import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../config/api_config.dart';
import '../../core/socket/socket_service.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_brand_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF9F9F9);
  static const Color red = Color(0xFFD42427);
}

class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key});

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadActiveQueues();

    SocketService.instance.onQueueUpdated((_) => _refreshQueues());
    SocketService.instance.onQueueCalled((_) => _refreshQueues());
    SocketService.instance.onQueueReady((_) => _refreshQueues());
  }

  void _refreshQueues() {
    if (mounted) {
      context.read<QueueCubit>().updateActiveQueuesSilently();
    }
  }

  String _categoryBadge(QueueModel queue) {
    if (queue.order?.isPreorder == true) return 'Atribut Sekolah';

    final name = queue.order?.orderItems.isNotEmpty == true
        ? queue.order!.orderItems.first.productName.toLowerCase()
        : '';

    if (name.contains('minum')) return 'Minuman';
    if (name.contains('makan')) return 'Makanan';
    if (name.contains('tulis') || name.contains('pulpen') || name.contains('pen')) return 'Alat Tulis';
    if (name.contains('atribut') || name.contains('seragam') || name.contains('batik') || name.contains('topi')) {
      return 'Atribut Sekolah';
    }
    return 'Produk';
  }

  IconData _categoryIcon(String badge) {
    switch (badge) {
      case 'Minuman':
        return Icons.local_drink_outlined;
      case 'Makanan':
        return Icons.restaurant_outlined;
      case 'Alat Tulis':
        return Icons.edit_outlined;
      case 'Atribut Sekolah':
        return Icons.checkroom_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  String? _productImageUrl(QueueModel queue) {
    final items = queue.order?.orderItems ?? [];
    if (items.isEmpty) return null;
    return items.first.imageUrl;
  }

  Widget _buildProductImage(QueueModel queue) {
    final imageUrl = _productImageUrl(queue);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _Ds.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(imageUrl),
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _Ds.primary),
                ),
              ),
              errorWidget: (_, __, ___) => Icon(
                _categoryIcon(_categoryBadge(queue)),
                size: 28,
                color: _Ds.hint,
              ),
            )
          : Icon(
              _categoryIcon(_categoryBadge(queue)),
              size: 28,
              color: _Ds.hint,
            ),
    );
  }

  String _cardTitle(QueueModel queue) {
    if (queue.order?.isPreorder == true) {
      final productName = queue.order?.orderItems.isNotEmpty == true
          ? queue.order!.orderItems.first.productName
          : 'Seragam';
      return 'Pre-Order $productName\nSMK Telkom Jakarta';
    }
    return 'Pesanan Koperasi';
  }

  String _referenceLabel(QueueModel queue) {
    return queue.order?.isPreorder == true ? 'Order ID' : 'Nomor Antrean';
  }

  String _referenceValue(QueueModel queue) {
    if (queue.order?.isPreorder == true && queue.order != null) {
      final no = queue.order!.orderNumber;
      return no.startsWith('#') ? no : '#$no';
    }
    return queue.queueNumber;
  }

  String _statusText(QueueModel queue) {
    if (queue.order?.isPreorder == true) {
      switch (queue.order!.status) {
        case OrderStatus.pending:
        case OrderStatus.paid:
          return 'Menunggu Produksi';
        case OrderStatus.preparing:
          return 'Sedang Disiapkan';
        case OrderStatus.inProduction:
          return 'Dalam Produksi';
        case OrderStatus.ready:
          return 'Siap Diambil';
        case OrderStatus.completed:
          return 'Selesai';
        case OrderStatus.cancelled:
          return 'Dibatalkan';
      }
    }

    switch (queue.status) {
      case QueueStatus.waiting:
        return 'Menunggu Antrean';
      case QueueStatus.preparing:
        return 'Sedang Disiapkan';
      case QueueStatus.ready:
        return 'Siap Diambil';
      case QueueStatus.completed:
        return 'Selesai';
      case QueueStatus.skipped:
        return 'Terlewat';
    }
  }

  void _openDetail(QueueModel queue) {
    if (queue.order?.isPreorder == true) {
      context.push('/queue/${queue.id}/tracking');
    } else {
      context.push('/queue/${queue.id}');
    }
  }

  Widget _buildCategoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _Ds.greenLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Ds.primary),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlightValue = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlightValue ? 16 : 14,
              fontWeight: highlightValue ? FontWeight.w800 : FontWeight.w400,
              color: highlightValue ? _Ds.red : _Ds.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(QueueModel queue) {
    final badge = _categoryBadge(queue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryBadge(badge),
              _buildProductImage(queue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cardTitle(queue),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(_referenceLabel(queue), _referenceValue(queue)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status', style: TextStyle(fontSize: 13, color: _Ds.textSecondary)),
              Text(
                _statusText(queue),
                style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openDetail(queue),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'LIHAT DETAIL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
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
            return _buildScrollPage(const [
              ProductGridShimmer(itemCount: 3),
            ]);
          }

          if (state is QueueError) {
            return _buildScrollPage([
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<QueueCubit>().loadActiveQueues(),
                ),
              ),
            ]);
          }

          if (state is QueueActiveLoaded) {
            final queues = state.activeQueues;

            if (queues.isEmpty) {
              return _buildScrollPage([
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: Center(
                    child: EmptyState(
                      emoji: '📋',
                      title: 'Kamu belum mengantre nih!',
                      subtitle: 'Yuk pesan makanan atau minuman favoritmu di katalog untuk mulai membuat antrean!',
                      actionButtonText: 'Pesan Sekarang',
                      onActionButtonPressed: () => context.go('/catalog'),
                    ),
                  ),
                ),
              ]);
            }

            return RefreshIndicator(
              color: _Ds.primary,
              onRefresh: () async => context.read<QueueCubit>().loadActiveQueues(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DamosBrandHeader(showTagline: false),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Halo, berikut adalah status antrean aktif Anda di Damos Mart SMK Telkom Jakarta.',
                            style: TextStyle(fontSize: 14, color: _Ds.textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(queues.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: index < queues.length - 1 ? 16 : 0),
                              child: _buildOrderCard(queues[index]),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildScrollPage([
            const SizedBox(
              height: 240,
              child: Center(child: Text('Menghubungkan ke Antrean...')),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildScrollPage(List<Widget> children) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosBrandHeader(showTagline: false),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
