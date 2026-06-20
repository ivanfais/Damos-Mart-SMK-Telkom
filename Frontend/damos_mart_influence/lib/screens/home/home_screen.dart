import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../blocs/cooperative/cooperative_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/damos_screen_header.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/product/damos_product_grid_card.dart';
import '../../widgets/common/pop_up_alert.dart';

/// Design system tokens (see global design system spec).
class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color red = Color(0xFFD42427);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _featuredProducts = [];
  ProductModel? _highlightProduct;
  bool _isLoadingFeatured = true;

  @override
  void initState() {
    super.initState();
    _loadHomeProducts();
    context.read<CooperativeCubit>().loadCurrentStatus();
    // Load the student's own active queue (if any) for the "Antrean Aktif" card.
    context.read<QueueCubit>().loadActiveQueues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeProducts() async {
    await Future.wait([
      _loadFeaturedProducts(),
      _loadHighlightProduct(),
    ]);
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      var products = await _productRepository.getFeaturedProducts(limit: 6);
      if (products.isEmpty) {
        final result = await _productRepository.getProducts(limit: 6, sort: 'newest');
        products = (result['products'] as List<ProductModel>?) ?? [];
      }
      if (mounted) {
        setState(() {
          _featuredProducts = products;
          _isLoadingFeatured = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFeatured = false);
      }
    }
  }

  Future<void> _loadHighlightProduct() async {
    try {
      ProductModel? highlight;

      for (final query in ['kitkat green tea', 'kitkat', 'green tea']) {
        final result = await _productRepository.getProducts(search: query, limit: 20);
        final products = (result['products'] as List<ProductModel>?) ?? [];
        highlight = _findKitKatGreenTeaProduct(products);
        if (highlight != null) break;
      }

      if (highlight == null) {
        final categories = await _productRepository.getCategories();
        final foodCategory = _findFoodCategory(categories);
        if (foodCategory != null) {
          final result = await _productRepository.getProducts(
            category: foodCategory.id,
            limit: 50,
          );
          final products = (result['products'] as List<ProductModel>?) ?? [];
          highlight = _findKitKatGreenTeaProduct(products);
        }
      }

      if (mounted) {
        setState(() => _highlightProduct = highlight);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _highlightProduct = null);
      }
    }
  }

  ProductModel? _findKitKatGreenTeaProduct(List<ProductModel> products) {
    for (final product in products) {
      final name = product.name.toLowerCase();
      if (name.contains('kitkat') && name.contains('green')) {
        return product;
      }
    }

    for (final product in products) {
      if (product.name.toLowerCase().contains('kitkat')) {
        return product;
      }
    }

    return null;
  }

  void _openHighlightProductDetail() {
    final product = _highlightProduct;
    if (product == null) return;
    context.push('/catalog/${product.id}');
  }

  CategoryModel? _findFoodCategory(List<CategoryModel> categories) {
    for (final category in categories) {
      final name = category.name.toLowerCase();
      if (name.contains('makan')) return category;
    }
    return null;
  }

  String _bannerSubtitle() => 'Telah Tersedia!';

  String _bannerTitle() {
    return _highlightProduct?.name ?? 'KitKat Green Tea Wafer Chocolate';
  }

  List<String> _bannerTitleLines() {
    final name = _bannerTitle();
    const prefix = 'kitkat green tea';
    final lower = name.toLowerCase();
    final prefixIndex = lower.indexOf(prefix);

    if (prefixIndex != -1) {
      final rest = name.substring(prefixIndex + prefix.length).trim();
      return [
        'KitKat Green Tea',
        rest.isNotEmpty ? rest : 'Wafer Chocolate',
      ];
    }

    return [name];
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<ProductCubit>().searchProducts(query.trim());
      context.go('/catalog');
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    if (product.isPreorder) {
      context.push('/preorder/${product.id}');
      return;
    }

    if (product.variants.length > 1) {
      context.push('/catalog/${product.id}');
      return;
    }

    final variantId = product.variants.isNotEmpty ? product.variants.first.id : null;

    await context.read<CartCubit>().addToCart(
      productId: product.id,
      variantId: variantId,
      quantity: 1,
    );

    if (!mounted) return;

    final cartState = context.read<CartCubit>().state;
    if (cartState is CartError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan ke keranjang: ${cartState.message}'),
          backgroundColor: _Ds.red,
        ),
      );
      return;
    }

    PopUpAlert.showAddedToCart(context: context, productName: product.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _Ds.primary,
        onRefresh: () async {
          setState(() => _isLoadingFeatured = true);
          context.read<QueueCubit>().loadActiveQueues();
          context.read<CooperativeCubit>().loadCurrentStatus();
          await _loadHomeProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DamosScreenHeader(
                searchController: _searchController,
                onSearchSubmitted: _submitSearch,
              ),
              _buildInfoCard(),
              const SizedBox(height: 12),
              _buildBannerCarousel(),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildActiveQueue(),
              _buildRecommendations(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. INFO KOPERASI
  // ---------------------------------------------------------------------------
  Color _statusColor(String status) {
    switch (status) {
      case 'Ramai':
        return _Ds.red;
      case 'Sepi':
        return _Ds.textSecondary;
      default:
        return _Ds.primary;
    }
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: _Ds.textPrimary),
                const SizedBox(width: 6),
                const Text(
                  'INFO KOPERASI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/info'),
                  child: const Text(
                    'Detail',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _Ds.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jam Operasional',
                          style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.access_time, size: 16, color: _Ds.textPrimary),
                          SizedBox(width: 6),
                          Text('07:00 - 16:00',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<CooperativeCubit, CooperativeState>(
                    builder: (context, coopState) {
                      final statusLabel = coopState is CooperativeLoaded
                          ? coopState.currentStatus.label
                          : 'Normal';
                      final statusColor = _statusColor(statusLabel);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kepadatan Toko',
                              style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(statusLabel,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PRODUK HIGHLIGHT (KitKat Green Tea)
  // ---------------------------------------------------------------------------
  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _highlightProduct != null ? _openHighlightProductDetail : null,
        child: _buildHighlightBanner(),
      ),
    );
  }

  Widget _buildHighlightBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 188,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppConstants.imageProductHighlight,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: _Ds.textPrimary,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fastfood_outlined,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.85],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _Ds.greenLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRODUK BARU',
                      style: TextStyle(
                        color: _Ds.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._bannerTitleLines().map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bannerSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionIcon(IconData icon) {
    return Icon(icon, color: _Ds.primary, size: 26);
  }

  Widget _buildInfoQuickIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: _Ds.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'i',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _Ds.greenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Ds.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. QUICK ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildQuickActionItem(
            label: 'Katalog',
            icon: _buildQuickActionIcon(Icons.grid_view_rounded),
            onTap: () => context.go('/catalog'),
          ),
          _buildQuickActionItem(
            label: 'Antrean',
            icon: _buildQuickActionIcon(Icons.hourglass_top_rounded),
            onTap: () => context.go('/queue'),
          ),
          _buildQuickActionItem(
            label: 'Informasi',
            icon: _buildInfoQuickIcon(),
            onTap: () => context.push('/info'),
          ),
          _buildQuickActionItem(
            label: 'Riwayat',
            icon: _buildQuickActionIcon(Icons.receipt_long_outlined),
            onTap: () => context.push('/profile/history'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ANTREAN AKTIF
  // ---------------------------------------------------------------------------
  Widget _buildActiveQueue() {
    return BlocBuilder<QueueCubit, QueueState>(
      builder: (context, state) {
        // Only show this section when the student has at least one active queue
        // (waiting / preparing / ready). Hidden entirely otherwise.
        QueueModel? queue;
        if (state is QueueActiveLoaded) {
          for (final q in state.activeQueues) {
            if (q.status == QueueStatus.waiting ||
                q.status == QueueStatus.preparing ||
                q.status == QueueStatus.ready) {
              queue = q;
              break;
            }
          }
        }
        if (queue == null) {
          return const SizedBox.shrink();
        }

        final label = _queueStatusLabel(queue.status);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Antrean Aktif',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Ds.textPrimary)),
                  GestureDetector(
                    onTap: () => context.go('/queue'),
                    child: const Text('Lihat Semua',
                        style: TextStyle(fontSize: 14, color: _Ds.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/queue/${queue!.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Ds.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nomor Antrean',
                              style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
                          const SizedBox(height: 4),
                          Text(queue.queueNumber,
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800, color: _Ds.primary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _Ds.greenLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _Ds.primary),
                        ),
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: _Ds.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _queueStatusLabel(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return 'MENUNGGU';
      case QueueStatus.preparing:
        return 'DISIAPKAN';
      case QueueStatus.ready:
        return 'SIAP DIAMBIL';
      case QueueStatus.completed:
        return 'SELESAI';
      case QueueStatus.skipped:
        return 'TERLEWAT';
    }
  }

  // ---------------------------------------------------------------------------
  // 6. REKOMENDASI PRODUK
  // ---------------------------------------------------------------------------
  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rekomendasi Produk',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Ds.textPrimary)),
              GestureDetector(
                onTap: () => context.go('/catalog'),
                child: const Text('Lainnya',
                    style: TextStyle(fontSize: 14, color: _Ds.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingFeatured)
            const ProductGridShimmer(itemCount: 4)
          else if (_featuredProducts.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text('Belum ada rekomendasi produk 😔',
                  style: TextStyle(color: _Ds.textSecondary)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _featuredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final product = _featuredProducts[index];
                return DamosProductGridCard(
                  product: product,
                  onTap: () => context.push('/catalog/${product.id}'),
                  onAddToCart: () => _addToCart(product),
                );
              },
            ),
        ],
      ),
    );
  }
}
