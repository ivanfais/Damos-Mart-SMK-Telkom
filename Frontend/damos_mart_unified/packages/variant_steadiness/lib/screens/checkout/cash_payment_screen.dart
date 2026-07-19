import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/order/order_cubit.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color iconBg = Color(0xFFF3F4F6);
}

class CashPaymentScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;

  const CashPaymentScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    }
  }

  String _tokenLabel(OrderModel order) {
    final queueNumber = order.queueNumber ?? order.orderNumber;
    return queueNumber.startsWith('#') ? queueNumber : '#$queueNumber';
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _Ds.iconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: _Ds.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Menunggu Pembayaran',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Ds.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tunjukkan kode token Antrean kepada petugas koperasi/kasir Damos Mart.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _Ds.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int number,
    required Widget content,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _Ds.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: content),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: _Ds.border),
      ],
    );
  }

  Widget _buildSteps(OrderModel order) {
    final token = _tokenLabel(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langkah-langkah Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        _buildStepItem(
          number: 1,
          content: const Text(
            'Datangi kasir terdekat di unit koperasi sekolah.',
            style: TextStyle(fontSize: 14, color: _Ds.textPrimary, height: 1.45),
          ),
        ),
        _buildStepItem(
          number: 2,
          content: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: _Ds.textPrimary, height: 1.45),
              children: [
                const TextSpan(text: 'Tunjukkan kode token '),
                TextSpan(
                  text: token,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: ' kepada kasir.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          number: 3,
          content: const Text(
            'Bayar dengan uang tunai sesuai total nominal.',
            style: TextStyle(fontSize: 14, color: _Ds.textPrimary, height: 1.45),
          ),
        ),
        _buildStepItem(
          number: 4,
          showDivider: false,
          content: const Text(
            'Ambil struk bukti pembayaran dan pesanan Anda.',
            style: TextStyle(fontSize: 14, color: _Ds.textPrimary, height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/queue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Ds.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Selesai & Lihat Antrean',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Column(
      children: [
        const SteadinessAppHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 28),
                _buildSteps(order),
              ],
            ),
          ),
        ),
        _buildActionButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded && _order == null) {
            setState(() => _order = state.order);
          }
        },
        builder: (context, state) {
          final order = _order;

          if (order == null) {
            return const Column(
              children: [
                SteadinessAppHeader(),
                Expanded(
                  child: Center(child: CircularProgressIndicator(color: _Ds.primary)),
                ),
              ],
            );
          }

          return _buildContent(order);
        },
      ),
    );
  }
}
