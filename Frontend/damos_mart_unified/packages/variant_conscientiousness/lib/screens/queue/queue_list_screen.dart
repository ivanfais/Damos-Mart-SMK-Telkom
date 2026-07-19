import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../config/api_config.dart';
import '../../config/app_constants.dart';
import '../../core/socket/socket_service.dart';
import '../../data/models/queue_model.dart';
import '../seragam/seragam_virtual_account_screen.dart' show SeragamOrderTracker;
import '../seragam/seragam_order_tracking_screen.dart';

class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key});

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);
  static const Color _red     = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadActiveQueues();
    SocketService.instance.onQueueUpdated(_onSocket);
    SocketService.instance.onQueueCalled(_onSocket);
    SocketService.instance.onQueueReady(_onSocket);
  }

  void _onSocket(dynamic data) {
    if (mounted) context.read<QueueCubit>().loadActiveQueues();
  }

  static const _seragamKeywords = ['seragam', 'baju', 'kemeja', 'batik', 'pramuka', 'olahraga', 'pakaian'];

  bool _isSeragamQueue(QueueModel q) {
    // Cek dari notes order (paling reliable)
    final notes = q.order?.notes?.toLowerCase() ?? '';
    if (notes.contains('seragam') || notes.contains('transfer bank')) return true;

    // Cek dari nama item
    final items = q.order?.orderItems ?? [];
    if (items.any((i) {
      final name = i.productName.toLowerCase();
      return _seragamKeywords.any((kw) => name.contains(kw));
    })) return true;

    return false;
  }

  String _statusLabel(QueueStatus s) {
    switch (s) {
      case QueueStatus.waiting:   return 'Menunggu Antrean';
      case QueueStatus.preparing: return 'Sedang Disiapkan';
      case QueueStatus.ready:     return 'Siap Diambil';
      case QueueStatus.completed: return 'Selesai';
      case QueueStatus.skipped:   return 'Terlewat';
    }
  }

  Color _statusColor(QueueStatus s) {
    switch (s) {
      case QueueStatus.waiting:   return const Color(0xFFF57C00);
      case QueueStatus.preparing: return const Color(0xFF1565C0);
      case QueueStatus.ready:     return _primary;
      default:                    return _grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: BlocBuilder<QueueCubit, QueueState>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: _primary,
                  onRefresh: () async => context.read<QueueCubit>().loadActiveQueues(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildBody(state),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 36, height: 36,
            child: Image.asset(AppConstants.imageLogo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.white, size: 28)),
          ),
          const SizedBox(width: 12),
          const Text('Damos Mart',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBody(QueueState state) {
    if (state is QueueLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(color: Color(0xFF018D1A)),
        ),
      );
    }

    if (state is QueueActiveLoaded && state.activeQueues.isNotEmpty) {
      // Auto-populate seragam tracker & filter dari antrian biasa
      for (final q in state.activeQueues) {
        if (_isSeragamQueue(q) && q.order != null) {
          SeragamOrderTracker.addOrder(q.order!);
        }
      }

      final active = state.activeQueues.where((q) =>
          !_isSeragamQueue(q) && // exclude seragam
          (q.status == QueueStatus.waiting ||
          q.status == QueueStatus.preparing ||
          q.status == QueueStatus.ready)).toList();

      if (active.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, berikut adalah status antrean aktif Anda di ${AppConstants.appName} ${AppConstants.schoolName}.',
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: _grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            ...active.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQueueCard(q),
                )),
          ],
        );
      }
    }

    // Empty state
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.hourglass_empty, size: 64, color: Color(0xFFCCCCCC)),
        const SizedBox(height: 16),
        const Text('Belum Ada Antrean',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _grey)),
        const SizedBox(height: 8),
        const Text(
          'Antrean Anda akan muncul di sini\nsetelah melakukan pemesanan.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF888888), height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () => context.go('/catalog'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Mulai Belanja',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueCard(QueueModel queue) {
    final statusColor = _statusColor(queue.status);
    final statusLabel = _statusLabel(queue.status);
    final imageUrl = queue.order?.orderItems.isNotEmpty == true
        ? queue.order!.orderItems.first.imageUrl
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF5E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Produk',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primary)),
                      ),
                      const SizedBox(height: 8),
                      const Text('Pesanan Koperasi',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nomor Antrean',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                          Text(queue.queueNumber,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _red)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                          Text(statusLabel,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(imageUrl),
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.push('/queue/${queue.id}'),
              style: TextButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12))),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('LIHAT DETAIL',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
