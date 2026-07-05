import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
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

  Future<void> _loadHistory(
    List<QueueModel> passedQueues, [
    String? userId,
  ]) async {
    try {
      final orders = await _orderRepository.getMyOrders();
      if (!mounted) return;
      setState(
        () => _history = QueueDisplayUtils.historyOrdersFromList(
          orders,
          passedQueues: passedQueues,
          userId: userId,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      context.read<QueueCubit>().reset();
      return;
    }

    final userId = authState.user.id;

    await context.read<QueueCubit>().loadActiveQueues(userId: userId);
    if (!mounted) return;

    final state = context.read<QueueCubit>().state;
    final passedQueues = state is QueueActiveLoaded ? state.passedQueues : const <QueueModel>[];
    await _loadHistory(passedQueues, userId);
  }

  void _handleQueueSocketEvent(dynamic data) {
    _refreshAll();
  }

  void _openPickupQr(QueueModel queue) {
    context.push('/queue/${queue.id}/qr');
  }

  void _openOrderStatus(QueueModel queue) {
    final orderId = queue.orderId;
    if (orderId.isNotEmpty) {
      context.push('/checkout/status/$orderId');
      return;
    }
    context.push('/queue/${queue.id}');
  }

  VoidCallback? _primaryAction(QueueModel queue) {
    if (QueueDisplayUtils.isPreorderQueue(queue)) {
      return () => _openOrderStatus(queue);
    }
    return () => _openPickupQr(queue);
  }

  String _primaryActionLabel(QueueModel queue) {
    if (QueueDisplayUtils.isPreorderQueue(queue)) {
      return 'Lihat Status Pesanan';
    }
    return 'QR Pengambilan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QueueDisplayColors.bg,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) {
                if (current is Unauthenticated) return true;
                if (current is! Authenticated) return false;
                if (previous is! Authenticated) return true;
                return previous.user.id != current.user.id;
              },
              listener: (context, authState) {
                setState(() => _history = []);
                context.read<QueueCubit>().reset();
                if (authState is Authenticated) {
                  _refreshAll();
                }
              },
              child: BlocListener<QueueCubit, QueueState>(
              listenWhen: (previous, current) => current is QueueActiveLoaded,
              listener: (context, queueState) {
                if (queueState is QueueActiveLoaded) {
                  final authState = context.read<AuthBloc>().state;
                  final userId = authState is Authenticated ? authState.user.id : null;
                  _loadHistory(queueState.passedQueues, userId);
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
                          onRetry: () {
                          final authState = context.read<AuthBloc>().state;
                          final userId = authState is Authenticated ? authState.user.id : null;
                          context.read<QueueCubit>().loadActiveQueues(userId: userId);
                        },
                        ),
                      ),
                    );
                  }

                  if (queueState is! QueueActiveLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState is Authenticated ? authState.user.id : null;
                        context.read<QueueCubit>().loadActiveQueues(userId: userId);
                      }
                    });
                    return const Center(
                      child: CircularProgressIndicator(color: QueueDisplayColors.primary),
                    );
                  }

                  final authState = context.read<AuthBloc>().state;
                  final userId = authState is Authenticated ? authState.user.id : '';
                  final activeQueues = userId.isEmpty
                      ? const <QueueModel>[]
                      : QueueDisplayUtils.sortedActiveQueues(
                          QueueDisplayUtils.queuesForUser(queueState.activeQueues, userId),
                        );

                  return QueueListBody(
                    activeQueues: activeQueues,
                    currentServing: queueState.currentServing,
                    totalWaiting: queueState.totalWaiting,
                    history: _history,
                    onEmptyAction: () => context.go('/catalog'),
                    onPrimaryAction: _primaryAction,
                    primaryActionLabel: _primaryActionLabel,
                    onRefresh: _onRefresh,
                  );
                },
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
