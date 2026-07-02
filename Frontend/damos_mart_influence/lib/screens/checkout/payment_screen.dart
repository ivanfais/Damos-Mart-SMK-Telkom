import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/order_model.dart';
import '../../config/api_config.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
}

class PaymentScreen extends StatefulWidget {
  final List<CartItemModel> items;

  const PaymentScreen({super.key, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.qris;
  bool _redirectToQris = false;

  double _calculateTotal() {
    return widget.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _submitOrder() {
    if (widget.items.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Oops! 😅',
        description: 'Keranjang belanjaanmu kosong atau tidak ada item untuk dibayar!',
        isError: true,
      );
      return;
    }

    final cartItemIds = widget.items.map((item) => item.id).toList();
    final methodStr = _selectedMethod == PaymentMethod.qris ? 'QRIS' : 'CASH_AT_COUNTER';

    if (_selectedMethod == PaymentMethod.qris) {
      setState(() => _redirectToQris = true);
      context.read<OrderCubit>().checkout(
            cartItemIds: cartItemIds,
            paymentMethod: methodStr,
            notes: '',
          );
      return;
    }

    context.read<OrderCubit>().checkout(
          cartItemIds: cartItemIds,
          paymentMethod: methodStr,
          notes: '',
        );
  }

  Widget _buildRadio({required bool selected}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _Ds.primary : _Ds.border, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: _Ds.primary, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }

  Widget _buildOrderItemCard(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 22),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _Ds.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jumlah: ${item.quantity}',
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Ds.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _Ds.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _Ds.primary : _Ds.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: _Ds.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _Ds.textPrimary),
              ),
            ),
            _buildRadio(selected: selected),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total, int itemCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal ($itemCount Produk)',
                style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Harga',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
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

  @override
  Widget build(BuildContext context) {
    final totalBill = _calculateTotal();
    final itemCount = widget.items.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            context.read<CartCubit>().loadCart();
            if (_redirectToQris) {
              setState(() => _redirectToQris = false);
              context.push('/checkout/qris/${state.order.id}', extra: state.order);
              return;
            }
            context.go('/checkout/ticket/${state.order.id}');
          } else if (state is OrderError) {
            if (_redirectToQris) {
              setState(() => _redirectToQris = false);
            }
            PopUpAlert.show(
              context: context,
              title: 'Gagal Memproses 😢',
              description: 'Terjadi kesalahan: ${state.message}. Coba lagi ya!',
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is OrderLoading;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DamosPageHeader(
                        title: 'Konfirmasi Pesanan',
                        showBackButton: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      const Text(
                        'Rincian Pesanan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                      ),
                      const Divider(height: 24, color: _Ds.borderLight),
                      ...List.generate(widget.items.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < widget.items.length - 1 ? 10 : 0),
                          child: _buildOrderItemCard(widget.items[index]),
                        );
                      }),
                      const SizedBox(height: 28),
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                      ),
                      const Divider(height: 24, color: _Ds.borderLight),
                      _buildPaymentOption(
                        method: PaymentMethod.qris,
                        icon: Icons.qr_code_scanner,
                        label: 'QRIS',
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentOption(
                        method: PaymentMethod.cashAtCounter,
                        icon: Icons.store_outlined,
                        label: 'Bayar di Kasir',
                      ),
                      const SizedBox(height: 28),
                      _buildSummaryCard(totalBill, itemCount),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Ds.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _Ds.border,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: _Ds.textSecondary, height: 1.4),
                          children: [
                            const TextSpan(text: 'Dengan menekan tombol di atas, Anda '),
                            TextSpan(
                              text: 'menyetujui syarat & ketentuan',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: _Ds.primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  PopUpAlert.show(
                                    context: context,
                                    title: 'Syarat & Ketentuan',
                                    description:
                                        'Dengan melanjutkan pembayaran, kamu menyetujui kebijakan pembelian dan pengambilan barang di Koperasi Damos Mart.',
                                  );
                                },
                            ),
                            const TextSpan(text: ' Damos Mart.'),
                          ],
                        ),
                      ),
                    ],
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
