import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/socket/socket_service.dart';
import '../../core/utils/queue_display_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/queue_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../widgets/queue/queue_status_widgets.dart';

class QueueDetailScreen extends StatefulWidget {
  final String queueId;

  const QueueDetailScreen({super.key, required this.queueId});

  @override
  State<QueueDetailScreen> createState() => _QueueDetailScreenState();
}

class _QueueDetailScreenState extends State<QueueDetailScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final QueueRepository _queueRepository = QueueRepository();

  QueueModel? _queue;
  List<OrderModel> _history = [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCancelling = false;

  String _currentServing = 'N/A';
  int _totalWaiting = 0;

  @override
  void initState() {
    super.initState();
    _loadData();

    SocketService.instance.onQueueUpdated(_handleSocketUpdate);
    SocketService.instance.onQueueCalled(_handleSocketUpdate);
    SocketService.instance.onQueueReady(_handleSocketUpdate);
  }

  void _handleSocketUpdate(dynamic data) {
    if (data != null && data['queueId'] == widget.queueId && mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _queueRepository.getQueueDetails(widget.queueId),
        _queueRepository.getCurrentQueueState(),
        _orderRepository.getMyOrders(),
      ]);

      if (!mounted) return;
      setState(() {
        _queue = results[0] as QueueModel;
        final stats = results[1] as Map<String, dynamic>;
        _currentServing = stats['currentServing']?.toString() ?? 'N/A';
        _totalWaiting = stats['totalWaiting'] as int? ?? 0;
        _history = QueueDisplayUtils.historyOrdersFromList(results[2] as List<OrderModel>);
        _errorMessage = null;
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

  Future<void> _confirmCancelQueue(QueueModel queue) async {
    await PopUpAlert.show(
      context: context,
      title: 'Batalkan Antrean?',
      description:
          'Antrean ${queue.queueNumber} akan dibatalkan. Pesanan terkait juga akan dibatalkan jika masih memungkinkan.',
      confirmText: 'Ya, Batalkan',
      cancelText: 'Tidak',
      isError: true,
      onConfirm: () => _cancelQueue(queue),
    );
  }

  Future<void> _cancelQueue(QueueModel queue) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);

    await context.read<OrderCubit>().cancelOrder(queue.orderId);
    if (!mounted) return;

    final orderState = context.read<OrderCubit>().state;
    if (orderState is OrderError) {
      PopUpAlert.show(
        context: context,
        title: 'Tidak Dapat Dibatalkan',
        description:
            'Antrean yang sudah dibayar tidak bisa dibatalkan dari aplikasi. Silakan hubungi petugas koperasi di loket.',
        isError: true,
      );
    } else {
      await PopUpAlert.showSuccess(
        context: context,
        title: 'Antrean Dibatalkan',
        description: 'Antrean kamu berhasil dibatalkan.',
      );
      if (!mounted) return;
      context.go('/queue');
    }

    if (mounted) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QueueDisplayColors.bg,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ProductGridShimmer(itemCount: 2),
      );
    }

    if (_errorMessage != null || _queue == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: ErrorState(
            message: _errorMessage ?? 'Gagal memuat detail antrean.',
            onRetry: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ),
      );
    }

    final queue = _queue!;

    return QueueStatusBody(
      queueNumber: queue.queueNumber,
      currentServing: _currentServing,
      totalWaiting: _totalWaiting,
      status: queue.status,
      history: _history,
      estimateMinutes: queue.estimatedWaitMinutes,
      isPrimaryActionLoading: _isCancelling,
      onPrimaryAction: () => _confirmCancelQueue(queue),
      onRefresh: _loadData,
    );
  }
}
