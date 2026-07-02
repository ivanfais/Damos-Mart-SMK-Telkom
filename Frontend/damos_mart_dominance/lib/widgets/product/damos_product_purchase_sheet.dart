import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../common/pop_up_alert.dart';

enum ProductPurchaseAction { buyNow, addToCart }

typedef DamosAddToCartSuccessCallback = Future<void> Function();

class DamosProductPurchaseSheet extends StatefulWidget {
  final ProductModel product;
  final ProductPurchaseAction action;
  final DamosAddToCartSuccessCallback? onAddToCartSuccess;

  const DamosProductPurchaseSheet({
    super.key,
    required this.product,
    required this.action,
    this.onAddToCartSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    required ProductPurchaseAction action,
    DamosAddToCartSuccessCallback? onAddToCartSuccess,
  }) {
    final cartCubit = context.read<CartCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: DamosProductPurchaseSheet(
          product: product,
          action: action,
          onAddToCartSuccess: onAddToCartSuccess,
        ),
      ),
    );
  }

  @override
  State<DamosProductPurchaseSheet> createState() => _DamosProductPurchaseSheetState();
}

class _DamosProductPurchaseSheetState extends State<DamosProductPurchaseSheet> {
  int _quantity = 1;
  ProductVariantModel? _selectedVariant;
  bool _isSubmitting = false;

  bool get _requiresVariant => widget.product.variants.isNotEmpty;

  bool get _hasSelectedVariant => !_requiresVariant || _selectedVariant != null;

  int get _maxStock {
    if (_requiresVariant) {
      return _selectedVariant?.stock ?? 0;
    }
    return widget.product.stock;
  }

  double get _unitPrice {
    var price = widget.product.price;
    if (_selectedVariant != null) {
      price += _selectedVariant!.additionalPrice;
    }
    return price;
  }

  bool get _isBuyNow => widget.action == ProductPurchaseAction.buyNow;

  bool get _canSubmit =>
      _hasSelectedVariant && _maxStock > 0 && !_isSubmitting;

  String get _primaryLabel =>
      _isBuyNow ? 'Beli Sekarang' : 'Masukan Keranjang';

  void _selectVariant(ProductVariantModel variant) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVariant = variant;
      _quantity = 1;
    });
  }

  void _incrementQty() {
    if (_quantity < _maxStock) {
      HapticFeedback.lightImpact();
      setState(() => _quantity++);
    }
  }

  void _decrementQty() {
    if (_quantity > 1) {
      HapticFeedback.lightImpact();
      setState(() => _quantity--);
    }
  }

  CartItemModel? _findCartItem(CartLoaded cartState) {
    final variantId = _selectedVariant?.id;
    for (final item in cartState.items) {
      if (item.productId != widget.product.id) continue;
      if (item.variantId == variantId) return item;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_canSubmit) return;
    if (!_hasSelectedVariant) return;

    final router = GoRouter.of(context);
    setState(() => _isSubmitting = true);

    final cartCubit = context.read<CartCubit>();
    try {
      await cartCubit.addToCart(
        productId: widget.product.id,
        variantId: _selectedVariant?.id,
        quantity: _quantity,
      );

      if (!mounted) return;

      final cartState = cartCubit.state;
      if (cartState is CartError) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal',
          description: cartState.message.contains('expired') ||
                  cartState.message.contains('UNAUTHORIZED')
              ? 'Sesi login habis. Silakan login ulang ya!'
              : cartState.message,
          isError: true,
        );
        return;
      }

      if (cartState is! CartLoaded) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal',
          description: 'Keranjang belum siap. Coba lagi ya!',
          isError: true,
        );
        return;
      }

      final cartItem = _findCartItem(cartState);
      if (cartItem == null) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal',
          description: 'Produk tidak ditemukan di keranjang.',
          isError: true,
        );
        return;
      }

      Navigator.of(context).pop();

      if (_isBuyNow) {
        router.push('/checkout', extra: [cartItem]);
        return;
      }

      final onSuccess = widget.onAddToCartSuccess;
      if (onSuccess != null) {
        await Future<void>.delayed(Duration.zero);
        await onSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
    );
  }

  Widget _buildSizeChip(ProductVariantModel variant) {
    final selected = _selectedVariant?.id == variant.id;

    return AnimatedScale(
      scale: selected ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? DamosDominanceColors.primary
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: DamosDominanceColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectVariant(variant),
            borderRadius: BorderRadius.circular(8),
            splashColor: DamosDominanceColors.primary.withValues(alpha: 0.15),
            highlightColor: DamosDominanceColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? DamosDominanceColors.textOnPrimary
                      : DamosDominanceColors.textPrimary.withValues(alpha: 0.7),
                ),
                child: Text(variant.variantName),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: DamosDominanceColors.fieldBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtySegment(
            icon: _quantity == 1 ? Icons.delete_outline : Icons.remove,
            onTap: !_hasSelectedVariant || _quantity == 1 ? null : _decrementQty,
          ),
          Container(width: 1, height: 24, color: DamosDominanceColors.fieldBorder),
          SizedBox(
            width: 40,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: DamosDominanceColors.fieldBorder),
          _qtySegment(
            icon: Icons.add,
            onTap: _hasSelectedVariant && _quantity < _maxStock
                ? _incrementQty
                : null,
          ),
        ],
      ),
    );
  }

  Widget _qtySegment({IconData? icon, VoidCallback? onTap}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: icon != null
              ? Icon(
                  icon,
                  size: 18,
                  color: onTap != null
                      ? DamosDominanceColors.textPrimary
                      : DamosDominanceColors.textHint,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: DamosDominanceColors.fieldBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ApiConfig.imageUrl(widget.product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : const ColoredBox(
                          color: Color(0xFFF3F4F6),
                          child: Icon(Icons.shopping_bag_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        CurrencyFormatter.format(_unitPrice),
                        key: ValueKey(_unitPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: DamosDominanceColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _hasSelectedVariant ? 'Stok: $_maxStock' : 'Stok: -',
                        key: ValueKey(_hasSelectedVariant ? _maxStock : 'empty'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: DamosDominanceColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.product.isPreorder)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Pre-Order',
                    style: TextStyle(
                      fontSize: 12,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          _divider(),
          if (widget.product.variants.isNotEmpty) ...[
            const Text(
              'Ukuran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.variants.map(_buildSizeChip).toList(),
            ),
            _divider(),
          ],
          Row(
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
              const Spacer(),
              _buildQuantityStepper(),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _canSubmit ? 1 : 0.85,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DamosDominanceColors.primary,
                  foregroundColor: DamosDominanceColors.textOnPrimary,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: DamosDominanceColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _primaryLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
