import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../core/socket/socket_service.dart';
import '../../core/utils/queue_display_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../widgets/queue/queue_status_widgets.dart';

class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key});

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> with WidgetsBindingObserver {
  final OrderRepository _orderRepository = OrderRepository();
  List<OrderModel> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();

    SocketService.instance.onQueueUpdated((data) => _handleQueueSocketEvent(data));
    SocketService.instance.onQueueCalled((_) => _refreshAll());
    SocketService.instance.onQueueReady((_) => _refreshAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _loadHistory([List<QueueModel> passedQueues = const []]) async {
    try {
      final orders = await _orderRepository.getMyOrders();
      if (!mounted) return;
      setState(
        () => _history = QueueDisplayUtils.historyOrdersFromList(
          orders,
          passedQueues: passedQueues,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    await context.read<QueueCubit>().loadActiveQueues();
    if (!mounted) return;

    final state = context.read<QueueCubit>().state;
    final passedQueues = state is QueueActiveLoaded ? state.passedQueues : const <QueueModel>[];
    await _loadHistory(passedQueues);
  }

  void _handleQueueSocketEvent(dynamic data) {
    _refreshAll();
  }

  QueueModel? _primaryQueue(QueueActiveLoaded state) {
    for (final queue in state.activeQueues) {
      if (queue.order?.isPreorder != true) return queue;
    }
    return state.activeQueues.isNotEmpty ? state.activeQueues.first : null;
  }

  void _openPickupQr(QueueModel queue) {
    context.push('/queue/${queue.id}/qr');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QueueDisplayColors.bg,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: BlocListener<QueueCubit, QueueState>(
              listenWhen: (previous, current) => current is QueueActiveLoaded,
              listener: (context, queueState) {
                if (queueState is QueueActiveLoaded) {
                  _loadHistory(queueState.passedQueues);
                }
              },
              child: BlocBuilder<QueueCubit, QueueState>(
              builder: (context, queueState) {
                if (queueState is QueueLoading) {
                  return const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: ProductGridShimmer(itemCount: 2),
                  );
                }

                if (queueState is QueueError) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: ErrorState(
                        message: queueState.message,
                        onRetry: () => context.read<QueueCubit>().loadActiveQueues(),
                      ),
                    ),
                  );
                }

                if (queueState is! QueueActiveLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.read<QueueCubit>().loadActiveQueues();
                    }
                  });
                  return const Center(
                    child: CircularProgressIndicator(color: QueueDisplayColors.primary),
                  );
                }

                final primaryQueue = _primaryQueue(queueState);

                if (primaryQueue == null) {
                  return RefreshIndicator(
                    color: QueueDisplayColors.primary,
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QueueEmptyCard(onAction: () => context.go('/catalog')),
                          const SizedBox(height: 14),
                          QueueCurrentServingCard(currentServing: queueState.currentServing),
                          const SizedBox(height: 22),
                          QueueHistorySection(history: _history),
                        ],
                      ),
                    ),
                  );
                }

                return QueueStatusBody(
                  queueNumber: primaryQueue.queueNumber,
                  currentServing: queueState.currentServing,
                  totalWaiting: queueState.totalWaiting,
                  status: primaryQueue.status,
                  history: _history,
                  estimateMinutes: primaryQueue.estimatedWaitMinutes,
                  primaryActionLabel: 'QR Pengambilan',
                  onPrimaryAction: () => _openPickupQr(primaryQueue),
                  onRefresh: _onRefresh,
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}
