import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class PickupTicketScreen extends StatefulWidget {
  final String orderId;

  const PickupTicketScreen({super.key, required this.orderId});

  @override
  State<PickupTicketScreen> createState() => _PickupTicketScreenState();
}

class _PickupTicketScreenState extends State<PickupTicketScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final QueueRepository _queueRepository = QueueRepository();

  OrderModel? _order;
  List<OrderModel> _history = [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCancelling = false;

  String _currentServing = 'N/A';
  int _totalWaiting = 0;
  QueueStatus _queueStatus = QueueStatus.waiting;
  int? _estimatedWaitMinutes;

  @override
  void initState() {
    super.initState();
    _loadData();

    SocketService.instance.onQueueUpdated((_) => _loadData());
    SocketService.instance.onQueueCalled((_) => _loadData());
    SocketService.instance.onQueueReady((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _orderRepository.getOrderDetails(widget.orderId),
        _orderRepository.getMyOrders(),
        _queueRepository.getCurrentQueueState(),
      ]);

      final order = results[0] as OrderModel;
      final orders = results[1] as List<OrderModel>;
      final stats = results[2] as Map<String, dynamic>;

      QueueStatus queueStatus = QueueStatus.waiting;
      int? estimatedWait;

      if (order.queueId != null && order.queueId!.isNotEmpty) {
        try {
          final queue = await _queueRepository.getQueueDetails(order.queueId!);
          queueStatus = queue.status;
          estimatedWait = queue.estimatedWaitMinutes;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _order = order;
        _history = QueueDisplayUtils.historyOrdersFromList(orders);
        _currentServing = stats['currentServing']?.toString() ?? 'N/A';
        _totalWaiting = stats['totalWaiting'] as int? ?? 0;
        _queueStatus = queueStatus;
        _estimatedWaitMinutes = estimatedWait;
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

  Future<void> _confirmCancelQueue(String queueNumber, String orderId) async {
    await PopUpAlert.show(
      context: context,
      title: 'Batalkan Antrean?',
      description:
          'Antrean $queueNumber akan dibatalkan. Pesanan terkait juga akan dibatalkan jika masih memungkinkan.',
      confirmText: 'Ya, Batalkan',
      cancelText: 'Tidak',
      isError: true,
      onConfirm: () => _cancelQueue(orderId),
    );
  }

  Future<void> _cancelQueue(String orderId) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);

    try {
      await _orderRepository.cancelOrder(orderId);
      if (!mounted) return;

      await PopUpAlert.showSuccess(
        context: context,
        title: 'Antrean Dibatalkan',
        description: 'Antrean kamu berhasil dibatalkan.',
      );
      if (!mounted) return;
      context.go('/queue');
    } catch (_) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Tidak Dapat Dibatalkan',
        description:
            'Antrean yang sudah dibayar tidak bisa dibatalkan dari aplikasi. Silakan hubungi petugas koperasi di loket.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
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

    if (_errorMessage != null || _order == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: ErrorState(
            message: _errorMessage ?? 'Gagal memuat data antrean.',
            onRetry: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ),
      );
    }

    final order = _order!;
    final queueNumber = order.queueNumber ?? order.orderNumber;

    return QueueStatusBody(
      queueNumber: queueNumber,
      currentServing: _currentServing,
      totalWaiting: _totalWaiting,
      status: _queueStatus,
      history: _history,
      estimateMinutes: _estimatedWaitMinutes,
      showSuccessBanner: true,
      isPrimaryActionLoading: _isCancelling,
      onPrimaryAction: () => _confirmCancelQueue(queueNumber, order.id),
      onRefresh: _loadData,
    );
  }
}
