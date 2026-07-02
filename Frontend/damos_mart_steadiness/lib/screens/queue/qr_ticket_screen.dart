import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/queue_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardHeaderBg = Color(0xFFF3F4F6);
}

class QRTicketScreen extends StatefulWidget {
  final String queueId;

  const QRTicketScreen({super.key, required this.queueId});

  @override
  State<QRTicketScreen> createState() => _QRTicketScreenState();
}

class _QRTicketScreenState extends State<QRTicketScreen> {
  final QueueRepository _queueRepository = QueueRepository();
  final OrderRepository _orderRepository = OrderRepository();

  QueueModel? _queue;
  List<OrderItemModel> _orderItems = [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queue = await _queueRepository.getQueueDetails(widget.queueId);
      var items = queue.order?.orderItems ?? <OrderItemModel>[];

      if (items.isEmpty) {
        final order = await _orderRepository.getOrderDetails(queue.orderId);
        items = order.orderItems;
      }

      if (!mounted) return;
      setState(() {
        _queue = queue;
        _orderItems = items;
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

  String _itemTitle(OrderItemModel item) => item.productName.trim();

  String? _itemSubtitle(OrderItemModel item) {
    final variant = item.variantName?.trim();
    if (variant != null && variant.isNotEmpty) return variant;
    return null;
  }

  String _statusLabel(QueueStatus status) {
    switch (status) {
      case QueueStatus.ready:
        return 'Siap Diambil';
      case QueueStatus.preparing:
        return 'Sedang Disiapkan';
      case QueueStatus.completed:
        return 'Selesai Diambil';
      case QueueStatus.skipped:
        return 'Dilewati';
      case QueueStatus.waiting:
        return 'Menunggu Antrean';
    }
  }

  String _queueToken(String queueNumber) {
    return queueNumber.startsWith('#') ? queueNumber : '#$queueNumber';
  }

  String _userFirstName(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final name = authState.user.fullName.trim();
      if (name.isNotEmpty) return name.split(' ').first;
    }
    return 'Pengguna';
  }

  Widget _buildStatusBadge(QueueStatus status) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: _Ds.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          _statusLabel(status),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard({
    required String queueNumber,
    required String qrData,
    required String userName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220,
            gapless: true,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _Ds.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _Ds.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _queueToken(queueNumber),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _Ds.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 15,
              color: _Ds.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: _Ds.border),
          ),
          const Text(
            'Tunjukkan QR ini ke petugas koperasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _Ds.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    final subtitle = _itemSubtitle(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemTitle(item),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Ds.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Ds.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} pcs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Ds.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _Ds.border, width: 1.5),
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: _Ds.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<OrderItemModel> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: _Ds.cardHeaderBg,
            child: const Text(
              'Daftar Barang',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _Ds.textPrimary,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Belum ada daftar barang.',
                style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  _buildItemRow(item),
                  if (index < items.length - 1)
                    const Divider(height: 1, color: _Ds.border),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildContent(QueueModel queue) {
    final userName = _userFirstName(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusBadge(queue.status),
          const SizedBox(height: 18),
          _buildQrCard(
            queueNumber: queue.queueNumber,
            qrData: queue.id,
            userName: userName,
          ),
          const SizedBox(height: 16),
          _buildItemsCard(_orderItems),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          LoadingShimmer(width: 140, height: 36, borderRadius: 20),
          SizedBox(height: 18),
          LoadingShimmer(width: double.infinity, height: 360, borderRadius: 12),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 220, borderRadius: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _errorMessage != null
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.6,
                          child: ErrorState(
                            message: _errorMessage!,
                            onRetry: _loadData,
                          ),
                        ),
                      )
                    : _buildContent(_queue!),
          ),
        ],
      ),
    );
  }
}
