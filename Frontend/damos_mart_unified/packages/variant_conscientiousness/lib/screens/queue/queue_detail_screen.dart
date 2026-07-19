import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../core/socket/socket_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart' show OrderModel, PaymentMethod, PaymentStatus;
import '../../data/models/queue_model.dart';
import '../../data/repositories/queue_repository.dart';
import '../../theme/app_colors.dart';

class QueueDetailScreen extends StatefulWidget {
  final String queueId;
  const QueueDetailScreen({super.key, required this.queueId});

  @override
  State<QueueDetailScreen> createState() => _QueueDetailScreenState();
}

class _QueueDetailScreenState extends State<QueueDetailScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _green10  = Color(0xFFDCF5E0);
  static const Color _border   = Color(0xFFCCCCCC);

  String _currentServing = 'N/A';
  int    _totalWaiting   = 0;

  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadQueueDetail(widget.queueId);
    _loadStats();
    SocketService.instance.onQueueUpdated(_onSocket);
    SocketService.instance.onQueueCalled(_onSocket);
    SocketService.instance.onQueueReady(_onSocket);
  }

  void _onSocket(dynamic data) {
    if (!mounted) return;
    context.read<QueueCubit>().updateQueueDetailSilently(widget.queueId);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await QueueRepository().getCurrentQueueState();
      if (!mounted) return;
      setState(() {
        _currentServing = s['currentServing']?.toString() ?? 'N/A';
        _totalWaiting   = s['totalWaiting'] as int? ?? 0;
      });
    } catch (_) {}
  }

  int? _seq(String num) {
    final m = RegExp(r'(\d+)$').firstMatch(num.trim());
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  ({double progress, int remaining}) _calcProgress(QueueModel q) {
    if (q.status == QueueStatus.ready || q.status == QueueStatus.completed) {
      return (progress: 1.0, remaining: 0);
    }
    final userSeq    = _seq(q.queueNumber);
    final currentSeq = _seq(_currentServing);
    if (userSeq == null || currentSeq == null || _currentServing == 'N/A') {
      return (progress: 0.3, remaining: _totalWaiting);
    }
    final remaining = (userSeq - currentSeq).clamp(0, 99);
    if (remaining == 0) return (progress: 0.9, remaining: 0);
    final total = remaining + 3;
    return (progress: ((total - remaining) / total).clamp(0.1, 0.85), remaining: remaining);
  }

  String _waitEstimate(QueueModel q) {
    if (q.estimatedWaitMinutes != null && q.status == QueueStatus.waiting) {
      return '${q.estimatedWaitMinutes} Menit';
    }
    return '10-15 Menit';
  }

  String _paymentStatusLabel(OrderModel? order) {
    if (order == null) return '-';
    if (order.paymentMethod == PaymentMethod.cashAtCounter && order.paymentStatus != PaymentStatus.paid) {
      return 'Belum Lunas/Bayar di Kasir';
    }
    if (order.paymentStatus == PaymentStatus.paid) return 'Berhasil';
    return 'Menunggu Pembayaran';
  }

  String _subtitle(QueueStatus s) {
    switch (s) {
      case QueueStatus.waiting:   return 'Pesanan Anda dalam antrean';
      case QueueStatus.preparing: return 'Pesanan Anda sedang disiapkan';
      case QueueStatus.ready:     return 'Pesanan Anda siap diambil';
      case QueueStatus.completed: return 'Pesanan Anda selesai';
      case QueueStatus.skipped:   return 'Antrean Anda terlewat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _buildBottomNav(),
      body: BlocBuilder<QueueCubit, QueueState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: RefreshIndicator(
                  color: _primary,
                  onRefresh: () async {
                    context.read<QueueCubit>().loadQueueDetail(widget.queueId);
                    await _loadStats();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: state is QueueDetailLoaded
                        ? _buildContent(state.queue)
                        : state is QueueLoading
                            ? _buildShimmer()
                            : const Center(child: Text('Memuat...')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      _BottomItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Keranjang'),
      _BottomItem(icon: Icons.hourglass_top_outlined,  activeIcon: Icons.hourglass_top,  label: 'Antrean'),
      _BottomItem(icon: Icons.home_outlined,           activeIcon: Icons.home,           label: 'Beranda'),
      _BottomItem(icon: Icons.grid_view_outlined,      activeIcon: Icons.grid_view,      label: 'Katalog'),
      _BottomItem(icon: Icons.person_outline,          activeIcon: Icons.person,         label: 'Profil'),
    ];
    const activeIndex = 1; // Antrean

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == activeIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    switch (i) {
                      case 0: context.go('/cart');    break;
                      case 1: context.go('/queue');   break;
                      case 2: context.go('/home');    break;
                      case 3: context.go('/catalog'); break;
                      case 4: context.go('/profile'); break;
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCF5E0) : Colors.white,
                      border: isActive
                          ? const Border(top: BorderSide(color: AppColors.primary, width: 2))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isActive ? item.activeIcon : item.icon,
                            size: 22,
                            color: isActive ? AppColors.primary : const Color(0xFF888888)),
                        const SizedBox(height: 3),
                        Text(item.label,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? AppColors.primary : const Color(0xFF888888))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Detail Antrean',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildContent(QueueModel queue) {
    final prog = _calcProgress(queue);
    final filledFlex = (prog.progress * 100).round().clamp(5, 95);
    final emptyFlex  = 100 - filledFlex;
    final servingLabel = _currentServing == 'N/A' ? '-' : _currentServing;
    final remainingLabel = prog.remaining <= 0 ? 'Antrean Anda' : 'Sisa ${prog.remaining} Antrean';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        const Text('Detail Antrean',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _dark)),
        const SizedBox(height: 4),
        Text(_subtitle(queue.status),
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: _grey)),
        const SizedBox(height: 20),

        // Main green card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _green10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _dark, width: 1.5),
                ),
                child: QrImageView(
                  data: 'DAMOS-MART|${queue.queueNumber}|${widget.queueId}',
                  version: QrVersions.auto,
                  size: 160,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF888888)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF888888)),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Tunjukkan kode QR ini ke kasir untuk\nmengambil pesanan Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _grey,
                    height: 1.4),
              ),
              const SizedBox(height: 16),

              // Queue number
              Text(queue.queueNumber,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                      height: 1,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('NOMOR ANTREAN',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _grey,
                      letterSpacing: 1.5)),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(flex: filledFlex, child: Container(color: _primary)),
                      Expanded(flex: emptyFlex, child: Container(color: const Color(0xFFCCCCCC))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sekarang: $servingLabel',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary)),
                  Text(remainingLabel,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: _primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info cards row
        Row(
          children: [
            // Estimasi Tunggu
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer_outlined, size: 24, color: _grey),
                    const SizedBox(height: 6),
                    const Text('Estimasi Tunggu',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 11, color: _grey)),
                    const SizedBox(height: 4),
                    Text(_waitEstimate(queue),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _dark)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Status badge card
            Expanded(child: _buildStatusCard(queue.status)),
          ],
        ),
        const SizedBox(height: 16),

        // Rincian data pesanan
        _buildOrderDetailCard(queue.order),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _grey)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
      ],
    );
  }

  Widget _buildOrderDetailCard(OrderModel? order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildOrderDetailRow('ID Pesanan', order?.orderNumber ?? '-'),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFB2DFB8)),
          const SizedBox(height: 10),
          _buildOrderDetailRow('Status Pembayaran', _paymentStatusLabel(order)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFB2DFB8)),
          const SizedBox(height: 10),
          _buildOrderDetailRow(
              'Waktu Transaksi', order != null ? DateFormatter.format(order.createdAt) : '-'),
        ],
      ),
    );
  }

  Widget _buildStatusCard(QueueStatus status) {
    Color bg;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case QueueStatus.waiting:
        bg        = const Color(0xFFFFF176);
        textColor = const Color(0xFF5D4037);
        icon      = Icons.error_outline;
        label     = 'Menunggu';
        break;
      case QueueStatus.preparing:
        bg        = const Color(0xFFBBDEFB);
        textColor = const Color(0xFF0D47A1);
        icon      = Icons.restaurant_outlined;
        label     = 'Disiapkan';
        break;
      case QueueStatus.ready:
        bg        = _green10;
        textColor = _primary;
        icon      = Icons.check_circle_outline;
        label     = 'Siap Ambil';
        break;
      case QueueStatus.completed:
        bg        = const Color(0xFFEEEEEE);
        textColor = _grey;
        icon      = Icons.task_alt;
        label     = 'Selesai';
        break;
      default:
        bg        = const Color(0xFFEEEEEE);
        textColor = _grey;
        icon      = Icons.warning_amber_outlined;
        label     = 'Terlewat';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: textColor),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Container(height: 24, width: 160, color: const Color(0xFFE0E0E0)),
        const SizedBox(height: 8),
        Container(height: 16, width: 120, color: const Color(0xFFE0E0E0)),
        const SizedBox(height: 20),
        Container(height: 320, decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(height: 100, color: const Color(0xFFE0E0E0))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 100, color: const Color(0xFFE0E0E0))),
        ]),
      ],
    );
  }
}

class _BottomItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _BottomItem({required this.icon, required this.activeIcon, required this.label});
}
