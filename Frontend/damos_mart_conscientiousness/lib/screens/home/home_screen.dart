import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../config/app_constants.dart';
import '../../config/api_config.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../core/utils/currency_formatter.dart';
import '../seragam/seragam_virtual_account_screen.dart' show SeragamOrderTracker;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary   = Color(0xFF018D1A);
  static const Color _bg        = Color(0xFFFCF8F8);
  static const Color _dark      = Color(0xFF111111);
  static const Color _grey      = Color(0xFF555555);
  static const Color _border    = Color(0xFFCCCCCC);
  static const Color _red       = Color(0xFFD32F2F);

  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    context.read<QueueCubit>().loadActiveQueues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hanya produk seragam/pakaian yang dikecualikan dari beranda (by nama produk)
  static const _excludedProductKeywords = [
    'baju', 'kemeja', 'seragam', 'batik', 'putih abu', 'pakaian', 'kaos',
  ];

  bool _isUniformProduct(ProductModel p) {
    final name = p.name.toLowerCase();
    return _excludedProductKeywords.any((kw) => name.contains(kw));
  }

  bool _isSeragamQueue(QueueModel q) {
    final notes = q.order?.notes?.toLowerCase() ?? '';
    if (notes.contains('seragam') || notes.contains('transfer bank')) return true;
    final items = q.order?.orderItems ?? [];
    return items.any((i) {
      final name = i.productName.toLowerCase();
      return _excludedProductKeywords.any((kw) => name.contains(kw));
    });
  }

  Future<void> _loadProducts() async {
    try {
      var products = await _productRepo.getFeaturedProducts(limit: 12);
      if (products.isEmpty) {
        final result = await _productRepo.getProducts(limit: 12, sort: 'newest');
        products = (result['products'] as List<ProductModel>?) ?? [];
      }
      // Exclude seragam/atribut produk
      products = products.where((p) => !_isUniformProduct(p)).take(6).toList();
      if (mounted) setState(() { _products = products; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<ProductCubit>().searchProducts(query.trim());
    context.go('/catalog');
  }

  void _openDetail(ProductModel product) {
    context.push('/catalog/${product.id}');
  }

  Future<void> _addToCart(ProductModel product) async {
    if (product.isPreorder) { context.push('/preorder/${product.id}'); return; }
    // Pakai varian pertama langsung tanpa buka detail
    final variantId = product.variants.isNotEmpty ? product.variants.first.id : null;
    await context.read<CartCubit>().addToCart(productId: product.id, variantId: variantId, quantity: 1);
    if (!mounted) return;
    final cartState = context.read<CartCubit>().state;
    if (cartState is CartError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${cartState.message}'), backgroundColor: _red),
      );
      return;
    }
    PopUpAlert.showAddedToCart(context: context, productName: 'Produk Ditambahkan\nKe Keranjang');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () async {
          setState(() => _isLoading = true);
          context.read<QueueCubit>().loadActiveQueues();
          await _loadProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildQuickMenu(),
              const SizedBox(height: 20),
              _buildQueueSection(),
              const SizedBox(height: 20),
              _buildCatalogSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              AppConstants.imageLogo,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('DM',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Damos Mart',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              Text('Melayani Kebutuhan, Mendukung Pendidikan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: _grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: _submitSearch,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _dark),
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: _border,
            ),
            GestureDetector(
              onTap: () => context.go('/catalog'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.filter_list, color: _grey, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK MENU ───────────────────────────────────────────────────────────
  Widget _buildQuickMenu() {
    final items = [
      _QuickMenuItem(icon: Icons.checkroom_outlined,     label: 'Katalog\nSeragam',     onTap: () => context.push('/seragam')),
      _QuickMenuItem(icon: Icons.receipt_long_outlined,  label: 'Riwayat\nTransaksi',   onTap: () => context.push('/profile/history')),
      _QuickMenuItem(icon: Icons.report_problem_outlined,label: 'Komplain\n& Retur',    onTap: () => context.push('/complaint')),
      _QuickMenuItem(icon: Icons.info_outline,           label: 'Informasi &\nNotifikasi', onTap: () => context.push('/info')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => _buildQuickMenuItem(item)).toList(),
      ),
    );
  }

  Widget _buildQuickMenuItem(_QuickMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDCF5E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: _primary, size: 28),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _dark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUEUE SECTION ────────────────────────────────────────────────────────
  Widget _buildQueueSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Antrean Anda',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _dark,
              )),
          const SizedBox(height: 10),
          BlocBuilder<QueueCubit, QueueState>(
            builder: (context, state) {
              QueueModel? activeQueue;
              if (state is QueueActiveLoaded) {
                for (final q in state.activeQueues) {
                  if (_isSeragamQueue(q)) continue; // exclude seragam, sama seperti antrian
                  if (q.status == QueueStatus.waiting ||
                      q.status == QueueStatus.preparing ||
                      q.status == QueueStatus.ready) {
                    activeQueue = q;
                    break;
                  }
                }
              }
              return _buildQueueCard(activeQueue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(QueueModel? queue) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomor Antrean',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                      )),
                  const SizedBox(height: 6),
                  if (queue != null)
                    Text(queue.queueNumber,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                          height: 1,
                          letterSpacing: 0.5,
                        ))
                  else
                    Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            if (queue != null)
              _buildQueueBadge(queue.status)
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Tidak Ada Antrean',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    )),
              ),
          ],
        ),
    );
  }

  Widget _buildQueueBadge(QueueStatus status) {
    Color bg;
    Color textColor;
    switch (status) {
      case QueueStatus.waiting:
        bg        = const Color(0xFFFFF176); // kuning
        textColor = const Color(0xFF5D4037);
        break;
      case QueueStatus.preparing:
        bg        = const Color(0xFFBBDEFB); // biru muda
        textColor = const Color(0xFF0D47A1);
        break;
      case QueueStatus.ready:
        bg        = const Color(0xFFDCF5E0); // hijau muda
        textColor = _primary;
        break;
      default:
        bg        = const Color(0xFFEEEEEE);
        textColor = _grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_queueLabel(status),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          )),
    );
  }

  String _queueLabel(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:   return 'Menunggu';
      case QueueStatus.preparing: return 'Disiapkan';
      case QueueStatus.ready:     return 'Siap Diambil';
      case QueueStatus.completed: return 'Selesai';
      case QueueStatus.skipped:   return 'Terlewat';
    }
  }

  // ─── CATALOG SECTION ──────────────────────────────────────────────────────
  Widget _buildCatalogSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Katalog Produk',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  )),
              GestureDetector(
                onTap: () => context.go('/catalog'),
                child: const Text('Lainnya',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            _buildProductShimmer()
          else if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada produk tersedia.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _grey)),
              ),
            )
          else
            _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(3, (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _shimmerCard()),
                const SizedBox(width: 10),
                Expanded(child: _shimmerCard()),
              ],
            ),
          ),
        )),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 64, height: 64, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 50, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 34, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 40, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 12, width: 60, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 26, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _products.length; i += 2) {
      final left  = _products[i];
      final right = i + 1 < _products.length ? _products[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildProductCard(left)),
              const SizedBox(width: 10),
              Expanded(child: right != null ? _buildProductCard(right) : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < _products.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildProductCard(ProductModel product) {
    final isAvailable = product.stock > 0 && !product.isPreorder;
    final categoryName = product.categoryName.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top: image + info — tap opens product detail
          GestureDetector(
            onTap: () => _openDetail(product),
            behavior: HitTestBehavior.opaque,
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed size image box
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholderImage(),
                            errorWidget: (_, __, ___) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Info — takes remaining width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: _grey,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 34,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _dark,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAvailable ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? _primary : _red,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ), // end GestureDetector
          // Bottom: heart + button — always at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.favorite_border, size: 18, color: _grey),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      onPressed: isAvailable ? () => _addToCart(product) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _grey.withOpacity(0.25),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Tambah Ke Keranjang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined, size: 26, color: Color(0xFFCCCCCC)),
    );
  }
}

class _QuickMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickMenuItem({required this.icon, required this.label, required this.onTap});
}
