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
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color badgeBg = Color(0xFFF0F0F0);
  static const Color imageBorder = Color(0xFFE8E8E8);
}

class PreorderScreen extends StatefulWidget {
  final String productId;

  const PreorderScreen({super.key, required this.productId});

  @override
  State<PreorderScreen> createState() => _PreorderScreenState();
}

class _PreorderScreenState extends State<PreorderScreen> {
  ProductVariantModel? _selectedVariant;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
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

  String _estimationLabel(ProductModel product) {
    final raw = product.preorderEstimation;
    if (raw == null || raw.isEmpty) {
      return 'Estimasi pengerjaan 14 hari kerja';
    }
    final lower = raw.toLowerCase();
    if (lower.contains('estimasi')) return raw;
    final days = _parseProductionDays(raw);
    return 'Estimasi pengerjaan $days hari kerja';
  }

  void _showSizeGuide() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Panduan Ukuran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ukuran seragam mengacu pada lingkar dada (cm):',
                style: TextStyle(fontSize: 14, color: _Ds.textSecondary, height: 1.5),
              ),
              SizedBox(height: 12),
              _SizeGuideRow(size: 'S', chest: '86 – 90'),
              _SizeGuideRow(size: 'M', chest: '91 – 95'),
              _SizeGuideRow(size: 'L', chest: '96 – 100'),
              _SizeGuideRow(size: 'XL', chest: '101 – 105'),
              _SizeGuideRow(size: 'XXL', chest: '106 – 110'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup', style: TextStyle(color: _Ds.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
        quantity: 1,
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

  Widget _buildHeader() {
    return SteadinessAppHeader(
      showNotificationButton: false,
      showCartButton: true,
      onCartTap: () => context.go('/cart'),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Ds.imageBorder),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: () {
          final displayImageUrl = product.displayImageUrl(selectedVariant: _selectedVariant);
          return displayImageUrl != null
            ? CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(displayImageUrl),
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _Ds.primary),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.shopping_bag_outlined,
                  color: _Ds.textSecondary,
                  size: 64,
                ),
              )
            : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 64);
        }(),
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
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _Ds.primary : _Ds.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _Ds.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelection(ProductModel product) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PILIH UKURAN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Ds.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < product.variants.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildSizeChip(
                    label: product.variants[i].variantName,
                    selected: _selectedVariant?.id == product.variants[i].id,
                    onTap: () => setState(() => _selectedVariant = product.variants[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _Ds.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _Ds.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Pre-Order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _Ds.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _estimationLabel(product),
            style: const TextStyle(
              fontSize: 14,
              color: _Ds.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showSizeGuide,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.straighten_rounded, size: 18, color: _Ds.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
                Text(
                  'Lihat Panduan Ukuran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _Ds.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: _Ds.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _Ds.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(_displayPrice(product)),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Ds.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _executePreorder(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Ds.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _Ds.border,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Checkout',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.shopping_cart_outlined, size: 20),
                        ],
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
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return Column(
              children: [
                _buildHeader(),
                const Expanded(child: ProductDetailShimmer()),
              ],
            );
          }

          if (state is ProductError) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ErrorState(
                    message: state.message,
                    onRetry: () => context.read<ProductCubit>().loadProductDetail(widget.productId),
                  ),
                ),
              ],
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductImage(product),
                        _buildSizeSelection(product),
                        _buildProductInfo(product),
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

class _SizeGuideRow extends StatelessWidget {
  const _SizeGuideRow({required this.size, required this.chest});

  final String size;
  final String chest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              size,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
          ),
          Text(
            '$chest cm',
            style: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
          ),
        ],
      ),
    );
  }
}
