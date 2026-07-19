import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../widgets/common/pop_up_alert.dart';

enum _PayMethod { qris, bankTransfer }

class SeragamPreorderPaymentScreen extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? variant;
  final int quantity;
  final String nama;
  final String kelas;

  const SeragamPreorderPaymentScreen({
    super.key,
    required this.product,
    required this.variant,
    required this.quantity,
    required this.nama,
    required this.kelas,
  });

  @override
  State<SeragamPreorderPaymentScreen> createState() => _SeragamPreorderPaymentScreenState();
}

class _SeragamPreorderPaymentScreenState extends State<SeragamPreorderPaymentScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);
  static const Color _green10 = Color(0xFFDCF5E0);

  _PayMethod _method     = _PayMethod.qris;
  bool _isLoading        = true;  // loading saat buat order di init
  bool _isProcessing     = false; // loading saat klik Bayar
  OrderModel? _order;             // satu order yang dibuat di init

  double get _subtotal =>
      (widget.product.price + (widget.variant?.additionalPrice ?? 0)) * widget.quantity;
  double get _adminFee => _subtotal * 0.01;
  double get _total    => _subtotal + _adminFee;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  Future<void> _createOrder() async {
    try {
      await context.read<CartCubit>().addToCart(
        productId: widget.product.id,
        variantId: widget.variant?.id,
        quantity: widget.quantity,
      );
      if (!mounted) return;
      await context.read<CartCubit>().loadCart();
      if (!mounted) return;

      final cartState = context.read<CartCubit>().state;
      if (cartState is! CartLoaded) {
        setState(() => _isLoading = false);
        return;
      }
      final item = cartState.items.where((i) =>
          i.productId == widget.product.id &&
          i.variantId == widget.variant?.id).firstOrNull;
      if (item == null) {
        setState(() => _isLoading = false);
        return;
      }

      // checkout() async — _isLoading akan false setelah listener OrderCreated/OrderError
      context.read<OrderCubit>().checkout(
        cartItemIds: [item.id],
        paymentMethod: 'QRIS',
        notes: 'Nama: ${widget.nama} | Kelas: ${widget.kelas} | Metode: Pre-Order Seragam',
      );
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bayar() {
    // Gunakan order yang sudah dibuat di init — tidak buat order baru
    final order = _order;
    if (order == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    // Update notes dengan metode yang baru dipilih user
    final metodeLabel = _method == _PayMethod.qris ? 'QRIS' : 'Transfer Bank';
    final patchedOrder = order.copyWith(
      notes: 'Nama: ${widget.nama} | Kelas: ${widget.kelas} | Metode: $metodeLabel',
    );

    if (_method == _PayMethod.qris) {
      setState(() => _isProcessing = false);
      context.push('/seragam-qris/${patchedOrder.id}', extra: patchedOrder);
    } else {
      setState(() => _isProcessing = false);
      context.push('/seragam-bank', extra: {'order': patchedOrder});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated && _order == null) {
            // Order berhasil dibuat saat init — simpan dan selesai loading
            setState(() {
              _order   = state.order;
              _isLoading = false;
            });
          } else if (state is OrderError && _isLoading) {
            setState(() => _isLoading = false);
            PopUpAlert.show(context: context, title: 'Gagal membuat pesanan', description: state.message, isError: true);
          }
        },
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Rincian Pesanan ──
                    const Text('Rincian Pesanan',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          // Product row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 72, height: 72,
                                  color: const Color(0xFFF0F0F0),
                                  child: () {
                                    final displayImageUrl = widget.product
                                        .displayImageUrl(selectedVariant: widget.variant);
                                    return displayImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: ApiConfig.imageUrl(displayImageUrl),
                                          fit: BoxFit.contain,
                                          errorWidget: (_, __, ___) => const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)))
                                      : const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC));
                                  }(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.product.name,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                                    if (widget.variant != null)
                                      Text('Size : ${widget.variant!.variantName}',
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Qty : ${widget.quantity}X',
                                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                                        Text(CurrencyFormatter.format(_subtotal),
                                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 8),
                          // Summary rows
                          _summaryRow('Subtotal', CurrencyFormatter.format(_subtotal)),
                          const SizedBox(height: 6),
                          _summaryRow('Biaya Administrasi', CurrencyFormatter.format(_adminFee)),
                          const SizedBox(height: 6),
                          _summaryRow('ID Pesanan',
                              _isLoading ? '...' : (_order?.orderNumber ?? '-')),
                          const SizedBox(height: 8),
                          const Divider(color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 8),
                          _summaryRow('Total Harga', CurrencyFormatter.format(_total), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Metode Pembayaran ──
                    const Text('Metode Pembayaran',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),

                    _methodOption(
                      method: _PayMethod.qris,
                      icon: Icons.qr_code_scanner,
                      label: 'QRIS',
                    ),
                    const SizedBox(height: 8),
                    _methodOption(
                      method: _PayMethod.bankTransfer,
                      icon: Icons.account_balance_outlined,
                      label: 'Transfer Bank',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom button ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _order == null) ? null : _bayar,
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.payment_outlined, size: 20),
                    label: const Text('Bayar Pre-Order',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      disabledBackgroundColor: _primary.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/seragam'),
          ),
          const Text('Rincian Pesanan',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: _dark)),
          Text(value, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? _primary : _dark)),
        ],
      );

  Widget _methodOption({required _PayMethod method, required IconData icon, required String label}) {
    final sel = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _green10 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? _primary : _border, width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _dark),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: _dark))),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? _primary : _border, width: 2)),
              child: sel ? Center(child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle))) : null,
            ),
          ],
        ),
      ),
    );
  }
}
