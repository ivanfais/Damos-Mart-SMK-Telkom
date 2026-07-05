import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/api_config.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color red = Color(0xFFD42427);
}

class PreorderScreen extends StatefulWidget {
  final String productId;

  const PreorderScreen({super.key, required this.productId});

  @override
  State<PreorderScreen> createState() => _PreorderScreenState();
}

class _PreorderScreenState extends State<PreorderScreen> {
  int _quantity = 1;
  ProductVariantModel? _selectedVariant;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  void _incrementQty() {
    setState(() => _quantity++);
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  double _displayPrice(ProductModel product) {
    var price = product.price;
    if (_selectedVariant != null) {
      price += _selectedVariant!.additionalPrice;
    }
    return price;
  }

  int _parseProductionDays(String? estimation) {
    if (estimation == null || estimation.isEmpty) return 14;
    final matches = RegExp(r'(\d+)').allMatches(estimation).map((m) => int.parse(m.group(1)!)).toList();
    if (matches.isEmpty) return 14;
    return matches.reduce((a, b) => a > b ? a : b);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  ({String session, String production, String arrival}) _preorderInfo(ProductModel product) {
    final production = product.preorderEstimation ?? '14 Hari Kerja';
    final days = _parseProductionDays(product.preorderEstimation);
    final now = DateTime.now();
    final sessionEnd = now.add(const Duration(days: 7));
    final arrival = _addBusinessDays(now, days);

    return (
      session: '${_formatDate(now)} - ${_formatDate(sessionEnd)}',
      production: production,
      arrival: _formatDate(arrival),
    );
  }

  Future<void> _executePreorder(ProductModel product) async {
    if (_isSubmitting) return;

    if (product.variants.isNotEmpty && _selectedVariant == null) {
      PopUpAlert.show(
        context: context,
        title: 'Pilih Ukuran',
        description: 'Silakan pilih ukuran seragam terlebih dahulu ya!',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<CartCubit>().addToCart(
        productId: product.id,
        variantId: _selectedVariant?.id,
        quantity: _quantity,
      );

      if (!mounted) return;

      final cartState = context.read<CartCubit>().state;
      if (cartState is CartError) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Pre-Order',
          description: cartState.message,
          isError: true,
        );
        return;
      }

      if (cartState is! CartLoaded) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Pre-Order',
          description: 'Keranjang belum siap. Coba lagi ya!',
          isError: true,
        );
        return;
      }

      final selectedVariantId = _selectedVariant?.id;
      CartItemModel? cartItem;
      for (final item in cartState.items) {
        if (item.productId == product.id && item.variantId == selectedVariantId) {
          cartItem = item;
          break;
        }
      }

      if (cartItem == null) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Pre-Order',
          description: 'Item pre-order tidak ditemukan di keranjang.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;
      context.push('/checkout', extra: [cartItem]);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildScrollHeader() {
    return DamosPageHeader(
      title: 'Damos Mart',
      showBackButton: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.go('/catalog'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.go('/cart'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollPage(Widget child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScrollHeader(),
          child,
        ],
      ),
    );
  }

  Widget _buildSizeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _Ds.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _Ds.primary : _Ds.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _Ds.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _Ds.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(icon: Icons.remove, onTap: _quantity > 1 ? _decrementQty : null),
          SizedBox(
            width: 40,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
            ),
          ),
          _qtyButton(icon: Icons.add, onTap: _incrementQty),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: onTap != null ? _Ds.textPrimary : _Ds.border),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool boldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
            color: _Ds.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreorderInfoCard(ProductModel product) {
    final info = _preorderInfo(product);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Ds.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 20, color: _Ds.primary),
              SizedBox(width: 8),
              Text(
                'INFORMASI PRE-ORDER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Ds.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Sesi Pemesanan:', info.session),
          const SizedBox(height: 12),
          _buildInfoRow('Estimasi Produksi:', info.production),
          const SizedBox(height: 12),
          _buildInfoRow('Estimasi Tiba:', info.arrival, boldValue: true),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Container(
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
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _executePreorder(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Ds.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Pre-Order Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return _buildScrollPage(const ProductDetailShimmer());
          }

          if (state is ProductError) {
            return _buildScrollPage(
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<ProductCubit>().loadProductDetail(widget.productId),
                ),
              ),
            );
          }

          if (state is ProductDetailLoaded) {
            final product = state.product;

            if (_selectedVariant == null && product.variants.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedVariant == null) {
                  setState(() => _selectedVariant = product.variants.first);
                }
              });
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScrollHeader(),
                        SizedBox(
                          height: 320,
                          width: double.infinity,
                          child: product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                                  width: double.infinity,
                                  height: 320,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  placeholder: (_, __) => Container(
                                    color: _Ds.bgGrey,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: _Ds.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: _Ds.bgGrey,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: _Ds.textSecondary,
                                      size: 64,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: _Ds.bgGrey,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: _Ds.textSecondary,
                                    size: 64,
                                  ),
                                ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PRE-ORDER badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _Ds.red),
                                ),
                                child: const Text(
                                  'PRE-ORDER',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Ds.red),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Name + price row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _Ds.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(_displayPrice(product)),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: _Ds.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'PRE-ORDER',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _Ds.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: _Ds.borderLight),
                              const SizedBox(height: 16),

                              // Size chips
                              if (product.variants.isNotEmpty) ...[
                                const Text(
                                  'PILIH UKURAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _Ds.textSecondary,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: product.variants.map((variant) {
                                    final selected = _selectedVariant?.id == variant.id;
                                    return _buildSizeChip(
                                      label: variant.variantName,
                                      selected: selected,
                                      onTap: () => setState(() => _selectedVariant = variant),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Quantity
                              const Text(
                                'JUMLAH PESANAN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _Ds.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildQuantitySelector(),

                              const SizedBox(height: 24),

                              // Info card
                              _buildPreorderInfoCard(product),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildBottomBar(product),
              ],
            );
          }

          return const Center(child: Text('Memuat pre-order...'));
        },
      ),
    );
  }
}
