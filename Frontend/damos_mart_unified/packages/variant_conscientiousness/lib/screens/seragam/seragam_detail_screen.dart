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
import '../../widgets/common/pop_up_alert.dart';

class SeragamDetailScreen extends StatefulWidget {
  final String productId;
  const SeragamDetailScreen({super.key, required this.productId});

  @override
  State<SeragamDetailScreen> createState() => _SeragamDetailScreenState();
}

class _SeragamDetailScreenState extends State<SeragamDetailScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);

  ProductVariantModel? _selectedVariant;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  Future<void> _preorder(ProductModel product) async {
    if (_selectedVariant == null && product.variants.isNotEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Pilih Ukuran',
        description: 'Silakan pilih ukuran seragam terlebih dahulu.',
        isError: true,
      );
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // Load cart dulu untuk cek apakah item sudah ada
      await context.read<CartCubit>().loadCart();
      if (!mounted) return;

      final existingState = context.read<CartCubit>().state;
      CartItemModel? existingItem;
      if (existingState is CartLoaded) {
        for (final i in existingState.items) {
          if (i.productId == product.id && i.variantId == _selectedVariant?.id) {
            existingItem = i;
            break;
          }
        }
      }

      if (existingItem != null) {
        // Update qty ke yang dipilih, bukan akumulasi
        await context.read<CartCubit>().updateQuantity(
          cartItemId: existingItem.id,
          quantity: _quantity,
        );
      } else {
        await context.read<CartCubit>().addToCart(
          productId: product.id,
          variantId: _selectedVariant?.id,
          quantity: _quantity,
        );
      }
      if (!mounted) return;

      // Reload untuk ambil item terbaru
      await context.read<CartCubit>().loadCart();
      if (!mounted) return;

      final cartState = context.read<CartCubit>().state;
      if (cartState is CartError) {
        PopUpAlert.show(context: context, title: 'Gagal', description: cartState.message, isError: true);
        return;
      }
      if (cartState is CartLoaded) {
        CartItemModel? item;
        for (final i in cartState.items) {
          if (i.productId == product.id && i.variantId == _selectedVariant?.id) {
            item = i;
            break;
          }
        }
        if (item != null) {
          context.push('/checkout', extra: [item]);
          return;
        }
      }
      PopUpAlert.show(context: context, title: 'Gagal', description: 'Item tidak ditemukan di keranjang.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double get _price {
    final s = context.read<ProductCubit>().state;
    if (s is ProductDetailLoaded) {
      return s.product.price + (_selectedVariant?.additionalPrice ?? 0);
    }
    return 0;
  }

  void _showSizeChart() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _SizeChartPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return _buildLoading();
          if (state is ProductDetailLoaded) return _buildDetail(state.product);
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildHeader(),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: _primary)),
        ),
      ],
    );
  }

  Widget _buildDetail(ProductModel product) {
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
                // ── Product Image (dalam rounded box) ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: () {
                      final displayImageUrl =
                          product.displayImageUrl(selectedVariant: _selectedVariant);
                      return displayImageUrl != null && displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(displayImageUrl),
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(color: _primary)),
                            errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.checkroom_outlined,
                                    size: 80, color: Color(0xFFCCCCCC))),
                          )
                        : const Center(
                            child: Icon(Icons.checkroom_outlined,
                                size: 80, color: Color(0xFFCCCCCC)));
                    }(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name + Price ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _dark,
                                    height: 1.3)),
                          ),
                          const SizedBox(width: 12),
                          Text(CurrencyFormatter.format(
                                  product.price + (_selectedVariant?.additionalPrice ?? 0)),
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _dark)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 16),

                      // ── Pilih Ukuran ──
                      if (product.variants.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('PILIH UKURAN',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _grey,
                                    letterSpacing: 0.8)),
                            GestureDetector(
                              onTap: _showSizeChart,
                              child: const Text('Panduan Ukuran',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _primary,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.variants.map((v) {
                            final selected = _selectedVariant?.id == v.id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedVariant = v;
                                _quantity = 1;
                              }),
                              child: Container(
                                width: 52,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? _primary : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: selected ? _primary : _border,
                                      width: 1.2),
                                ),
                                child: Text(v.variantName,
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? Colors.white : _dark)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Jumlah Pesanan ──
                      const Text('JUMLAH PESANAN',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _grey,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      _buildQtySelector(),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 16),

                      // ── Deskripsi ──
                      const Text('Deskripsi Produk',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 8),
                      Text(product.description ?? 'Belum ada deskripsi.',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: _grey,
                              height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom Button ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/seragam-info', extra: {
                  'product': product,
                  'variant': _selectedVariant,
                  'quantity': _quantity,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pre-Order Sekarang',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/seragam'),
          ),
          const Text('Detail Seragam',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildQtySelector() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove,
              _quantity > 1 ? () => setState(() => _quantity--) : null),
          SizedBox(
            width: 44,
            child: Text('$_quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _dark)),
          ),
          _qtyBtn(Icons.add, () => setState(() => _quantity++)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => SizedBox(
        width: 42, height: 42,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18,
              color: onTap != null ? _dark : _border),
          onPressed: onTap,
        ),
      );
}

// ─── SIZE CHART POPUP ──────────────────────────────────────────────────────
class _SizeChartPopup extends StatelessWidget {
  const _SizeChartPopup();

  static const Color _primary = Color(0xFF018D1A);
  static const Color _red     = Color(0xFFD32F2F);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF777777);

  static const _headers = ['UKURAN', 'PANJANG\nBAJU', 'LINGKAR\nDADA', 'LEBAR\nPUNGGUNG', 'LENGAN\nPENDEK', 'LENGAN\nPANJANG'];
  static const _rows = [
    ['S',   '60', '104', '43', '25', '59'],
    ['M',   '65', '108', '46', '26', '60'],
    ['L',   '70', '113', '47', '27', '61'],
    ['XL',  '74', '116', '50', '28', '62'],
    ['XXL', '76', '120', '51', '29', '63'],
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFDCF5E0),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Panduan Ukuran Seragam',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111))),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),

          // Satuan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: const [
                Text('SATUAN UKURAN: CENTIMETER (CM)',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _grey,
                        letterSpacing: 0.5)),
              ],
            ),
          ),

          // Table
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Table(
                border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 1),
                columnWidths: const {
                  0: FixedColumnWidth(44),
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                    children: _headers.map((h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          child: Text(h,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _dark)),
                        )).toList(),
                  ),
                  // Data rows
                  ..._rows.map((row) => TableRow(
                        children: row.asMap().entries.map((e) {
                          final isSize = e.key == 0;
                          final isXL = row[0] == 'XL' || row[0] == 'XXL';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            child: Text(e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: isSize
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSize
                                        ? (isXL ? _red : _primary)
                                        : _dark)),
                          );
                        }).toList(),
                      )),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text('* Ketuk tabel untuk menutup panduan ukuran',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _grey.withOpacity(0.7),
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
