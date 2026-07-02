import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/home/damos_active_order_card.dart';
import '../../widgets/home/damos_home_header.dart';
import '../../widgets/home/damos_home_product_card.dart';
import '../../widgets/home/damos_home_product_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final OrderRepository _orderRepository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _buyAgainProducts = [];
  List<ProductModel> _recommendedProducts = [];
  bool _isLoadingBuyAgain = true;
  bool _isLoadingRecommended = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    context.read<QueueCubit>().loadActiveQueues();
    context.read<CartCubit>().loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      _loadBuyAgainProducts(),
      _loadRecommendedProducts(),
    ]);
  }

  Future<void> _loadBuyAgainProducts() async {
    try {
      final orders = await _orderRepository.getMyOrders();
      final seen = <String>{};
      final productIds = <String>[];

      for (final order in orders) {
        for (final item in order.orderItems) {
          if (seen.add(item.productId)) {
            productIds.add(item.productId);
          }
          if (productIds.length >= 12) break;
        }
        if (productIds.length >= 12) break;
      }

      final products = <ProductModel>[];
      for (final id in productIds) {
        try {
          products.add(await _productRepository.getProductDetail(id));
        } catch (_) {
          // Skip products that no longer exist.
        }
      }

      if (mounted) {
        setState(() {
          _buyAgainProducts = products;
          _isLoadingBuyAgain = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBuyAgain = false);
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      var products = await _productRepository.getFeaturedProducts(limit: 12);
      if (products.isEmpty) {
        final result = await _productRepository.getProducts(limit: 12, sort: 'newest');
        products = (result['products'] as List<ProductModel>?) ?? [];
      }
      if (mounted) {
        setState(() {
          _recommendedProducts = products;
          _isLoadingRecommended = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecommended = false);
    }
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<ProductCubit>().searchProducts(query.trim());
      context.go('/catalog');
    }
  }

  List<QueueModel> _activeQueues(QueueState state) {
    if (state is! QueueActiveLoaded) return [];

    return state.activeQueues
        .where(
          (queue) =>
              queue.status == QueueStatus.waiting ||
              queue.status == QueueStatus.preparing ||
              queue.status == QueueStatus.ready,
        )
        .toList();
  }

  Future<void> _openQueueDetail(QueueModel queue) async {
    await context.push('/orders/${queue.orderId}');
    if (!mounted) return;
    context.read<QueueCubit>().restoreActiveQueuesView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: RefreshIndicator(
        color: DamosDominanceColors.primary,
        onRefresh: () async {
          setState(() {
            _isLoadingBuyAgain = true;
            _isLoadingRecommended = true;
          });
          context.read<QueueCubit>().loadActiveQueues();
          await _loadHomeData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DamosHomeHeader(
                searchController: _searchController,
                onSearchSubmitted: _submitSearch,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: BlocBuilder<QueueCubit, QueueState>(
                  builder: (context, state) {
                    final queues = _activeQueues(state);
                    if (queues.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        for (var i = 0; i < queues.length; i++) ...[
                          DamosActiveOrderCard(
                            queue: queues[i],
                            onTapDetail: () => _openQueueDetail(queues[i]),
                          ),
                          if (i < queues.length - 1) const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
              _buildProductSection(
                title: 'Beli Lagi',
                isLoading: _isLoadingBuyAgain,
                products: _buyAgainProducts,
                emptyMessage: 'Belum ada riwayat pembelian',
                onSeeAll: () => context.go('/history'),
              ),
              const SizedBox(height: 20),
              _buildProductSection(
                title: 'Rekomendasi Untuk Anda',
                isLoading: _isLoadingRecommended,
                products: _recommendedProducts,
                emptyMessage: 'Belum ada rekomendasi produk',
                onSeeAll: () => context.go('/catalog'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required bool isLoading,
    required List<ProductModel> products,
    required String emptyMessage,
    required VoidCallback onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'Lihat Semua >',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        isLoading
            ? DamosHomeProductCarousel(
                children: List.generate(
                  4,
                  (_) => const LoadingShimmer(
                    width: DamosHomeProductCard.cardWidth,
                    height: DamosHomeProductCard.cardHeight,
                    borderRadius: 8,
                  ),
                ),
              )
            : products.isEmpty
                ? SizedBox(
                    height: DamosHomeProductCard.cardHeight,
                    child: Center(
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(
                          color: DamosDominanceColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : DamosHomeProductCarousel(
                    children: [
                      for (final product in products)
                        BlocBuilder<FavoriteCubit, FavoriteState>(
                          builder: (context, _) {
                            final isFavorite =
                                context.read<FavoriteCubit>().isFavorite(product.id);
                            return DamosHomeProductCard(
                              product: product,
                              isFavorite: isFavorite,
                              onTap: () => context.push('/catalog/${product.id}'),
                              onFavoriteTap: () =>
                                  context.read<FavoriteCubit>().toggleFavorite(product.id),
                            );
                          },
                        ),
                    ],
                  ),
      ],
    );
  }
}
