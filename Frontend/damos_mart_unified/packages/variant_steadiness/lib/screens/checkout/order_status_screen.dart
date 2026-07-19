import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../core/socket/socket_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/order_status_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/queue_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../widgets/order/order_status_stepper.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFF9FAFB);
  static const Color infoBg = Color(0xFFF3F4F6);
}

class OrderStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> with WidgetsBindingObserver {
  final OrderRepository _orderRepository = OrderRepository();
  final QueueRepository _queueRepository = QueueRepository();

  OrderModel? _order;
  QueueStatus? _queueStatus;
  int? _estimatedWaitMinutes;
  String? _errorMessage;
  bool _isLoading = true;
  Timer? _pollTimer;
  bool _isRefreshing = false;

  late final void Function(dynamic) _socketRefreshHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _socketRefreshHandler = _handleQueueSocketEvent;
    _loadData();

    SocketService.instance.onQueueUpdated(_socketRefreshHandler);
    SocketService.instance.onQueueCalled(_socketRefreshHandler);
    SocketService.instance.onQueueReady(_socketRefreshHandler);
    SocketService.instance.onOrderStatusUpdated(_socketRefreshHandler);

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshSilently());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    SocketService.instance.offQueueUpdated(_socketRefreshHandler);
    SocketService.instance.offQueueCalled(_socketRefreshHandler);
    SocketService.instance.offQueueReady(_socketRefreshHandler);
    SocketService.instance.offOrderStatusUpdated(_socketRefreshHandler);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSilently();
    }
  }

  bool _isRelevantSocketEvent(dynamic data) {
    if (data is! Map) return true;

    final orderId = data['orderId']?.toString();
    if (orderId != null && orderId == widget.orderId) return true;

    final queueId = data['queueId']?.toString();
    final currentQueueId = _order?.queueId;
    if (queueId != null &&
        currentQueueId != null &&
        currentQueueId.isNotEmpty &&
        queueId == currentQueueId) {
      return true;
    }

    return orderId == null && queueId == null;
  }

  void _handleQueueSocketEvent(dynamic data) {
    if (!_isRelevantSocketEvent(data)) return;
    _refreshSilently();
  }

  Future<void> _refreshSilently() {
    if (_isRefreshing) return Future.value();
    return _loadData(silent: true);
  }

  Future<void> _loadData({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final order = await _orderRepository.getOrderDetails(widget.orderId);
      QueueStatus? queueStatus;
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
        _queueStatus = queueStatus;
        _estimatedWaitMinutes = estimatedWait;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  String _queueNumberLabel(OrderModel order) {
    final raw = order.queueNumber ?? order.orderNumber;
    if (raw.startsWith('#')) return raw;
    return '#$raw';
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

  String _estimatePickupLabel(OrderModel order) {
    if (_queueStatus == QueueStatus.ready || order.status == OrderStatus.ready) {
      return 'Siap sekarang';
    }

    if (order.isPreorder) {
      final baseDate = order.paidAt ?? order.createdAt;
      final estimateDate = _addBusinessDays(baseDate, 14);
      return DateFormatter.formatShort(estimateDate);
    }

    final base = order.paidAt ?? order.createdAt;
    final minutes = _estimatedWaitMinutes ?? 15;
    final estimate = base.add(Duration(minutes: minutes));
    return '${DateFormat('HH:mm').format(estimate)} WIB';
  }

  double _adminFee(OrderModel order) {
    final fee = order.total - order.subtotal;
    return fee > 0 ? fee : 500;
  }

  Widget _buildStatusCard(OrderModel order) {
    final activeStep = OrderStatusUtils.activeStepIndex(
      order: order,
      queueStatus: _queueStatus,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nomor Antrean',
                      style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _queueNumberLabel(order),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _Ds.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Estimasi Ambil',
                      style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _estimatePickupLabel(order),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _Ds.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          OrderStatusStepper(activeIndex: activeStep),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(OrderModel order) {
    final activeStep = OrderStatusUtils.activeStepIndex(
      order: order,
      queueStatus: _queueStatus,
    );
    final message = OrderStatusUtils.infoMessage(order: order, activeStep: activeStep);

    return Container(
      decoration: BoxDecoration(
        color: _Ds.infoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: const BoxDecoration(
              color: _Ds.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _Ds.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _Ds.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    final imageUrl = item.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _Ds.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Ds.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ApiConfig.imageUrl(imageUrl),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.shopping_bag_outlined,
                      color: _Ds.textSecondary,
                      size: 24,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Ds.primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x Unit',
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _Ds.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Pesanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Ds.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < order.orderItems.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: _Ds.border),
                _buildOrderItem(order.orderItems[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    final adminFee = _adminFee(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', CurrencyFormatter.format(order.subtotal)),
          const SizedBox(height: 8),
          _priceRow('Biaya Admin', CurrencyFormatter.format(adminFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _Ds.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bayar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _Ds.primary,
                ),
              ),
              Text(
                CurrencyFormatter.format(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _Ds.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
        ),
      ],
    );
  }

  Widget _buildQrButton(OrderModel order) {
    final activeStep = OrderStatusUtils.activeStepIndex(
      order: order,
      queueStatus: _queueStatus,
    );
    final canShowQr = activeStep >= 2 &&
        order.queueId != null &&
        order.queueId!.isNotEmpty;

    if (!canShowQr) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/queue/${order.queueId}/qr'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _Ds.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.qr_code_2_outlined, size: 20),
          label: const Text(
            'Lihat QR Pengambilan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Column(
      children: [
        _buildQrButton(order),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/checkout/receipt/${order.id}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _Ds.primary,
              side: const BorderSide(color: _Ds.border),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            label: const Text(
              'Lihat Struk Digital',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ProductGridShimmer(itemCount: 3),
      );
    }

    if (_errorMessage != null || _order == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: ErrorState(
            message: _errorMessage ?? 'Gagal memuat status pesanan.',
            onRetry: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ),
      );
    }

    final order = _order!;

    return RefreshIndicator(
      color: _Ds.primary,
      onRefresh: () => _loadData(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(order),
            const SizedBox(height: 14),
            _buildInfoBanner(order),
            const SizedBox(height: 22),
            _buildOrderDetails(order),
            const SizedBox(height: 16),
            _buildPriceSummary(order),
            const SizedBox(height: 32),
            _buildActionButtons(order),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: Column(
        children: [
          const SteadinessTitleHeader(title: 'Status Pesanan'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
