import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/preorder_date_utils.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/pop_up_alert.dart';

class _CheckoutStyle {
  static const double cardRadius = 12;
  static const Color cardBorder = DamosDominanceColors.fieldBorder;
  static const Color selectedFill = Color(0xFFE8F5E9);
  static const Color iconInactiveFill = Color(0xFFF3F4F6);
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
  bool _redirectToCash = false;
  String? _preorderEstimateRange;
  bool _loadingPreorderEstimate = false;

  bool get _hasPreorderItems => widget.items.any((item) => item.isPreorder);

  @override
  void initState() {
    super.initState();
    if (_hasPreorderItems) {
      _loadPreorderEstimate();
    }
  }

  Future<void> _loadPreorderEstimate() async {
    setState(() => _loadingPreorderEstimate = true);

    try {
      final repo = ProductRepository();
      var maxDays = 14;

      for (final item in widget.items.where((i) => i.isPreorder)) {
        final product = await repo.getProductDetail(item.productId);
        final days = PreorderDateUtils.parseProductionDays(product.preorderEstimation);
        if (days > maxDays) maxDays = days;
      }

      if (!mounted) return;
      setState(() {
        _preorderEstimateRange = PreorderDateUtils.completionRange(maxDays);
        _loadingPreorderEstimate = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preorderEstimateRange = PreorderDateUtils.completionRange(14);
        _loadingPreorderEstimate = false;
      });
    }
  }

  double get _subtotal =>
      widget.items.fold(0.0, (sum, item) => sum + item.subtotal);

  void _submitOrder() {
    if (widget.items.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Oops!',
        description: 'Keranjang belanjaanmu kosong atau tidak ada item untuk dibayar!',
        isError: true,
      );
      return;
    }

    final cartItemIds = widget.items.map((item) => item.id).toList();
    final methodStr =
        _selectedMethod == PaymentMethod.qris ? 'QRIS' : 'CASH_AT_COUNTER';

    if (_selectedMethod == PaymentMethod.qris) {
      setState(() => _redirectToQris = true);
      context.read<OrderCubit>().checkout(
            cartItemIds: cartItemIds,
            paymentMethod: methodStr,
            notes: '',
          );
      return;
    }

    setState(() => _redirectToCash = true);
    context.read<OrderCubit>().checkout(
          cartItemIds: cartItemIds,
          paymentMethod: methodStr,
          notes: '',
        );
  }

  Widget _lineDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _CheckoutStyle.cardBorder,
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_CheckoutStyle.cardRadius),
        border: Border.all(color: _CheckoutStyle.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: DamosDominanceColors.textPrimary,
        ),
      ),
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required bool active,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? DamosDominanceColors.primary : _CheckoutStyle.iconInactiveFill,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: active ? Colors.white : DamosDominanceColors.textSecondary,
      ),
    );
  }

  Widget _buildPreorderCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Produk Pre-Order (PO)'),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingPreorderEstimate)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    'Estimasi selesai ${_preorderEstimateRange ?? PreorderDateUtils.completionRange(14)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Pesanan masuk antrean produksi setelah pembayaran diverifikasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: DamosDominanceColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupMethodCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Metode Pengambilan'),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _circleIcon(icon: Icons.storefront_outlined, active: true),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Pickup',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DamosDominanceColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ambil langsung di koperasi sekolah',
                        style: TextStyle(
                          fontSize: 12,
                          color: DamosDominanceColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderLine(CartItemModel item, {required bool showDivider}) {
    final variantLabel = item.variantName != null && item.variantName!.isNotEmpty
        ? 'Size: ${item.variantName} x${item.quantity}'
        : 'x${item.quantity}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      variantLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DamosDominanceColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(item.subtotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) _lineDivider(),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Ringkasan Pesanan'),
          _lineDivider(),
          ...List.generate(widget.items.length, (index) {
            return _buildOrderLine(
              widget.items[index],
              showDivider: index < widget.items.length - 1,
            );
          }),
          _lineDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 13,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_subtotal),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Biaya Layanan',
                      style: TextStyle(
                        fontSize: 13,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Gratis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DamosDominanceColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio({required bool selected}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? DamosDominanceColors.primary
              : DamosDominanceColors.fieldBorder,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: DamosDominanceColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool showDivider,
  }) {
    final selected = _selectedMethod == method;

    return Column(
      children: [
        Material(
          color: selected ? _CheckoutStyle.selectedFill : Colors.white,
          child: InkWell(
            onTap: () => setState(() => _selectedMethod = method),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _circleIcon(icon: icon, active: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DamosDominanceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DamosDominanceColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRadio(selected: selected),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) _lineDivider(),
      ],
    );
  }

  Widget _buildPaymentMethodsCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Metode Pembayaran'),
          _lineDivider(),
          _buildPaymentOption(
            method: PaymentMethod.qris,
            icon: Icons.qr_code_2_outlined,
            label: 'QRIS',
            subtitle: 'Scan QR Code untuk bayar',
            showDivider: true,
          ),
          _buildPaymentOption(
            method: PaymentMethod.cashAtCounter,
            icon: Icons.payments_outlined,
            label: 'Bayar di Kasir',
            subtitle: 'Bayar langsung ke kasir koperasi',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool isLoading}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _CheckoutStyle.cardBorder),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    color: DamosDominanceColors.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(_subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DamosDominanceColors.primary,
                  foregroundColor: DamosDominanceColors.textOnPrimary,
                  disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Konfirmasi Pesanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            if (_redirectToQris) {
              setState(() => _redirectToQris = false);
              context.read<CartCubit>().loadCart();
              context.push('/checkout/qris/${state.order.id}', extra: state.order);
              return;
            }
            if (_redirectToCash) {
              setState(() => _redirectToCash = false);
              context.read<CartCubit>().loadCart();
              context.push('/checkout/cash/${state.order.id}', extra: state.order);
              return;
            }
          } else if (state is OrderError) {
            if (_redirectToQris) {
              setState(() => _redirectToQris = false);
            }
            if (_redirectToCash) {
              setState(() => _redirectToCash = false);
            }
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DamosPageHeader(
                        title: 'Checkout',
                        showBackButton: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          children: [
                            if (_hasPreorderItems) ...[
                              _buildPreorderCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildPickupMethodCard(),
                            const SizedBox(height: 16),
                            _buildOrderSummaryCard(),
                            const SizedBox(height: 16),
                            _buildPaymentMethodsCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(isLoading: isLoading),
            ],
          );
        },
      ),
    );
  }
}
