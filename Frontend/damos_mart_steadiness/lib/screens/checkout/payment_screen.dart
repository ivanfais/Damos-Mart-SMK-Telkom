import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color selectedBg = Color(0xFFF3F4F6);
  static const double serviceFee = 500;
}

enum _PaymentOption { cashAtCounter, qris }

class PaymentScreen extends StatefulWidget {
  final List<CartItemModel> items;

  const PaymentScreen({super.key, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PaymentOption _selectedMethod = _PaymentOption.cashAtCounter;
  bool _redirectToQris = false;

  double _subtotal() {
    return widget.items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  double _grandTotal() {
    return _subtotal() + _Ds.serviceFee;
  }

  void _submitOrder() {
    if (widget.items.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Keranjang Kosong',
        description: 'Tidak ada item untuk dibayar.',
        isError: true,
      );
      return;
    }

    final cartItemIds = widget.items.map((item) => item.id).toList();

    if (_selectedMethod == _PaymentOption.qris) {
      setState(() => _redirectToQris = true);
      context.read<OrderCubit>().checkout(
            cartItemIds: cartItemIds,
            paymentMethod: 'QRIS',
            notes: '',
          );
      return;
    }

    context.read<OrderCubit>().checkout(
          cartItemIds: cartItemIds,
          paymentMethod: 'CASH_AT_COUNTER',
          notes: '',
        );
  }

  Widget _buildOrderSummary() {
    final itemCount = widget.items.length;
    final subtotal = _subtotal();
    final total = _grandTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal ($itemCount item)', CurrencyFormatter.format(subtotal)),
          const SizedBox(height: 8),
          _summaryRow('Biaya Layanan', CurrencyFormatter.format(_Ds.serviceFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _Ds.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, color: _Ds.textSecondary)),
      ],
    );
  }

  Widget _buildPaymentOption({
    required _PaymentOption method,
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    final selected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _Ds.selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _Ds.textPrimary : _Ds.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: _Ds.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _Ds.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _Ds.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _Ds.border, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            final cartItemIds = widget.items.map((item) => item.id).toList();
            context.read<CartCubit>().removeCheckedOutItems(cartItemIds);
            if (_redirectToQris) {
              setState(() => _redirectToQris = false);
              context.push('/checkout/qris/${state.order.id}', extra: state.order);
              return;
            }
            context.go('/checkout/cash/${state.order.id}', extra: state.order);
          } else if (state is OrderError) {
            if (_redirectToQris) setState(() => _redirectToQris = false);
            PopUpAlert.show(
              context: context,
              title: 'Gagal Memproses',
              description: 'Terjadi kesalahan: ${state.message}. Coba lagi ya!',
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is OrderLoading;

          return Column(
            children: [
              const SteadinessTitleHeader(title: 'Pembayaran'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOrderSummary(),
                      const SizedBox(height: 22),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'METODE PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _Ds.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      _buildPaymentOption(
                        method: _PaymentOption.cashAtCounter,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Bayar Di Kasir',
                      ),
                      _buildPaymentOption(
                        method: _PaymentOption.qris,
                        icon: Icons.qr_code_2_outlined,
                        label: 'QRIS',
                        subtitle: 'OVO, GoPay, Dana, LinkAja',
                      ),
                    ],
                  ),
                ),
              ),
              Container(
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
                      onPressed: isLoading ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Ds.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _Ds.border,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Bayar Sekarang',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
