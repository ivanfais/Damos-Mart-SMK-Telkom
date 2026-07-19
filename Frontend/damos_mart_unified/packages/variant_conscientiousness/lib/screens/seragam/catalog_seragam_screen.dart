import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../config/app_constants.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import 'seragam_virtual_account_screen.dart' show SeragamPendingOrder, SeragamOrderTracker;
import 'seragam_order_tracking_screen.dart';

class CatalogSeragamScreen extends StatefulWidget {
  const CatalogSeragamScreen({super.key});

  @override
  State<CatalogSeragamScreen> createState() => _CatalogSeragamScreenState();
}

class _CatalogSeragamScreenState extends State<CatalogSeragamScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);

  // Kata kunci nama produk seragam
  static const _seragamKeywords = [
    'seragam', 'baju', 'kemeja', 'batik', 'putih abu',
    'pakaian', 'kaos', 'pramuka', 'olahraga',
  ];

  final ProductRepository _repo = ProductRepository();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeragam();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild banner setelah kembali dari QRIS/VA
    setState(() {});
  }

  bool _isSeragam(ProductModel p) {
    final name = p.name.toLowerCase();
    final cat  = p.categoryName.toLowerCase();
    return _seragamKeywords.any((kw) => name.contains(kw)) ||
        cat.contains('seragam');
  }

  Future<void> _loadSeragam() async {
    try {
      // Ambil semua produk, lalu filter seragam
      final result = await _repo.getProducts(limit: 100);
      final all = (result['products'] as List<ProductModel>? ?? []);
      final seragam = all.where(_isSeragam).toList();
      if (mounted) setState(() { _products = seragam; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SeragamOrderTrackingScreen())),
        backgroundColor: _primary,
        icon: const Icon(Icons.track_changes, color: Colors.white),
        label: const Text('Lacak\nPesanan',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2)),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadSeragam();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (SeragamPendingOrder.pendingOrder != null)
              SliverToBoxAdapter(child: _buildPendingBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: const Text('Katalog Seragam',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    )),
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildShimmer(),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.checkroom_outlined,
                          size: 56, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 12),
                      Text('Belum ada produk seragam',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: _grey)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCard(_products[i]),
                    ),
                    childCount: _products.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ─── REMINDER BANNER ─────────────────────────────────────────────────────
  Widget _buildPendingBanner() {
    final pending = SeragamPendingOrder.pendingOrder;
    if (pending == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Perhatian:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                Text('Anda memiliki 1 pesanan\nyang belum dibayar.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                final bank = SeragamPendingOrder.pendingBank;
                if (bank != null) {
                  // Langsung ke VA dengan bank yang sudah dipilih sebelumnya
                  context.push('/seragam-va', extra: {'order': pending, 'bank': bank});
                } else {
                  context.push('/seragam-qris/${pending.id}', extra: pending);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Bayar Sekarang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(AppConstants.imageLogo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: Colors.white24, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('DM',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    )),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Damos Mart',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text('Melayani Kebutuhan, Mendukung Pendidikan',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────
  Widget _buildCard(ProductModel product) {
    final stok = product.stock;
    final hasStock = stok > 0;
    final stokLabel = hasStock ? '$stok' : '-';

    return GestureDetector(
      onTap: () => context.push('/seragam/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: SizedBox(
                width: 130,
                height: 130,
                child: () {
                  final displayImageUrl = product.displayImageUrl();
                  return displayImageUrl != null && displayImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(displayImageUrl),
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: const Color(0xFFF0F0F0),
                            alignment: Alignment.center,
                            child: const Icon(Icons.checkroom_outlined,
                                size: 32, color: Color(0xFFCCCCCC))),
                        errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF0F0F0),
                            alignment: Alignment.center,
                            child: const Icon(Icons.checkroom_outlined,
                                size: 32, color: Color(0xFFCCCCCC))),
                      )
                    : Container(
                        color: const Color(0xFFF0F0F0),
                        alignment: Alignment.center,
                        child: const Icon(Icons.checkroom_outlined,
                            size: 32, color: Color(0xFFCCCCCC)));
                }(),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        )),
                    const SizedBox(height: 4),
                    Text('Stok Tersedia : $stokLabel',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _grey,
                        )),
                    const SizedBox(height: 6),
                    Text(CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        )),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () => context.push('/seragam/${product.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          disabledBackgroundColor:
                              _primary.withOpacity(0.45),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Pesan Pre-Order',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHIMMER ──────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
