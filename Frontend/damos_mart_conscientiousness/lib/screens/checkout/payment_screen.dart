import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

enum PaymentMethod { qris, cashAtCounter }

class PaymentScreen extends StatefulWidget {
  final List<CartItemModel> items;
  const PaymentScreen({super.key, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _green10  = Color(0xFFDCF5E0);

  PaymentMethod _method  = PaymentMethod.qris;
  OrderModel?   _order;
  bool _isCreating       = false;
  bool _isPaying         = false;

  double get _total =>
      widget.items.fold(0.0, (s, i) => s + i.subtotal);

  String get _methodLabel =>
      _method == PaymentMethod.qris ? 'QRIS' : 'Bayar di Kasir';

  @override
  void initState() {
    super.initState();
    // Buat order otomatis saat screen dibuka agar ID Pesanan langsung muncul
    _createOrder();
  }

  void _createOrder() {
    if (widget.items.isEmpty) return;
    setState(() => _isCreating = true);
    context.read<OrderCubit>().checkout(
      cartItemIds: widget.items.map((i) => i.id).toList(),
      paymentMethod: 'QRIS',
      notes: '',
    );
  }

  void _submit() {
    final order = _order;
    if (order == null) return;
    setState(() => _isPaying = true);

    if (_method == PaymentMethod.qris) {
      context.read<CartCubit>().loadCart();
      context.push('/checkout/qris/${order.id}', extra: order);
    } else {
      context.read<OrderCubit>().payOrder(order.id, paymentMethod: 'CASH_AT_COUNTER');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated && _isCreating) {
            // Order berhasil dibuat saat screen load → simpan & tampilkan ID
            setState(() {
              _order = state.order;
              _isCreating = false;
            });
          } else if (state is OrderDetailLoaded && _isPaying) {
            setState(() => _isPaying = false);
            context.go('/checkout/success', extra: state.order);
          } else if (state is OrderError) {
            setState(() { _isCreating = false; _isPaying = false; });
            PopUpAlert.show(
              context: context,
              title: 'Gagal Memproses',
              description: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isLoading = _isCreating || _isPaying || state is OrderLoading;
          return Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Rincian Pesanan ──
                      const Text('Rincian Pesanan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 8),
                      ...widget.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildItemCard(item),
                          )),

                      const SizedBox(height: 16),

                      // ── Ringkasan Pesanan card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _green10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ringkasan Pesanan',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _dark)),
                            const SizedBox(height: 12),
                            // ID Pesanan
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ID Pesanan',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: _dark)),
                                _isCreating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: _primary))
                                    : Text(
                                        _order?.orderNumber ?? '-',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _dark)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Metode Pembayaran',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: _dark)),
                                Text(_methodLabel,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _dark)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Color(0xFFB2DFB8)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Tagihan',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _dark)),
                                Text(CurrencyFormatter.format(_total),
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _dark)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Metode Pembayaran ──
                      const Text('Metode Pembayaran',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 8),
                      _buildMethodOption(
                        method: PaymentMethod.qris,
                        icon: Icons.qr_code_scanner,
                        label: 'QRIS',
                      ),
                      const SizedBox(height: 8),
                      _buildMethodOption(
                        method: PaymentMethod.cashAtCounter,
                        icon: Icons.store_outlined,
                        label: 'Bayar di Kasir',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ──
              Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading || _order == null ? null : _submit,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white)))
                              : const Icon(Icons.payment_outlined, size: 20),
                          label: const Text('Bayar Sekarang',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _border,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _grey,
                              height: 1.4),
                          children: [
                            const TextSpan(
                                text:
                                    'Dengan menekan tombol di atas, Anda '),
                            TextSpan(
                              text: 'menyetujui syarat & ketentuan',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => PopUpAlert.show(
                                      context: context,
                                      title: 'Syarat & Ketentuan',
                                      description:
                                          'Dengan melanjutkan pembayaran, kamu menyetujui kebijakan pembelian dan pengambilan barang di Koperasi Damos Mart.',
                                    ),
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

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Text('Rincian Pesanan',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ─── ITEM CARD ────────────────────────────────────────────────────────────
  Widget _buildItemCard(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 56,
              height: 56,
              color: const Color(0xFFF0F0F0),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFFCCCCCC),
                          size: 22))
                  : const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFFCCCCCC), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
                const SizedBox(height: 2),
                Text('${item.quantity}X',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: _grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(CurrencyFormatter.format(item.subtotal),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dark)),
        ],
      ),
    );
  }

  // ─── METHOD OPTION ────────────────────────────────────────────────────────
  Widget _buildMethodOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _green10 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? _primary : _border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _dark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _dark)),
            ),
            _buildRadio(selected),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: selected ? _primary : _border, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: _primary, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
