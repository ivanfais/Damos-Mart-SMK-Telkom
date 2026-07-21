import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../blocs/product/product_cubit.dart';
import '../../data/models/category_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/catalog/damos_catalog_category_chips.dart';
import '../../widgets/catalog/damos_catalog_header.dart';
import '../../widgets/catalog/damos_catalog_product_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final productCubit = context.read<ProductCubit>();
    final state = productCubit.state;
    if (state is ProductCatalogLoaded && state.searchQuery.isNotEmpty) {
      productCubit.loadCatalog(categoryId: state.selectedCategoryId);
    } else if (state is! ProductCatalogLoaded && state is! ProductLoading) {
      productCubit.loadCatalog();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.of(context).routerDelegate.addListener(_onRouteChanged);
    });

    final cartState = context.read<CartCubit>().state;
    if (cartState is! CartLoaded) {
      context.read<CartCubit>().loadCart();
    }

    final favoriteState = context.read<FavoriteCubit>().state;
    if (favoriteState is FavoriteInitial) {
      context.read<FavoriteCubit>().loadFavoriteIds();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    GoRouter.of(context).routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    if (location != '/catalog') return;

    final cubit = context.read<ProductCubit>();
    final state = cubit.state;
    if (state is ProductCatalogLoaded && state.searchQuery.isNotEmpty) {
      cubit.loadCatalog(categoryId: state.selectedCategoryId);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductCubit>().loadMore();
    }
  }

  Widget _buildHeader() {
    return const DamosCatalogHeader();
  }

  String _chipLabelForCategoryId(String selectedCategoryId, List<CategoryModel> categories) {
    if (selectedCategoryId.isEmpty) return 'Semua';

    final category = categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    if (category == null) return 'Semua';

    final name = category.name.toLowerCase();
    if (name.contains('makan')) return 'Makanan';
    if (name.contains('minum')) return 'Minuman';
    if (name.contains('atribut') || name.contains('seragam')) return 'Atribut Sekolah';
    if (name.contains('tulis') || name.contains('sekolah')) return 'Alat Tulis';
    return 'Semua';
  }

  String _categoryIdForChip(String chipLabel, List<CategoryModel> categories) {
    if (chipLabel == 'Semua') return '';

    final keyword = switch (chipLabel) {
      'Makanan' => 'makan',
      'Minuman' => 'minum',
      'Atribut Sekolah' => 'atribut',
      'Alat Tulis' => 'tulis',
      _ => '',
    };

    if (keyword.isEmpty) return '';

    final match = categories.where((c) {
      final name = c.name.toLowerCase();
      if (keyword == 'atribut') {
        return name.contains('atribut') || name.contains('seragam');
      }
      return name.contains(keyword);
    }).firstOrNull;

    return match?.id ?? '';
  }

  Widget _buildCategorySection(String selectedCategoryId, List<CategoryModel> categories) {
    final selectedChip = _chipLabelForCategoryId(selectedCategoryId, categories);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: DamosCatalogCategoryChips(
        selectedLabel: selectedChip,
        onSelected: (label) {
          final categoryId = _categoryIdForChip(label, categories);
          context.read<ProductCubit>().filterByCategory(categoryId);
        },
      ),
    );
  }

  Widget _buildProductGridSliver(ProductCatalogLoaded state) {
    if (state.products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            emoji: '🔍',
            title: 'Produk tidak ditemukan',
            subtitle: 'Coba cari dengan kata kunci lain ya!',
            actionButtonText: 'Reset Filter',
            onActionButtonPressed: () {
              context.read<ProductCubit>().loadCatalog();
            },
          ),
        ),
      );
    }

    final itemCount = state.products.length + (state.isLoadMoreRunning ? 2 : 0);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: DamosCatalogProductCard.cardHeight,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.products.length) {
              return const LoadingShimmer(
                width: DamosCatalogProductCard.cardWidth,
                height: DamosCatalogProductCard.cardHeight,
                borderRadius: 8,
              );
            }

            final product = state.products[index];
            return BlocBuilder<FavoriteCubit, FavoriteState>(
              builder: (context, favoriteState) {
                final isFavorite = context.read<FavoriteCubit>().isFavorite(product.id);
                return DamosCatalogProductCard(
                  product: product,
                  isFavorite: isFavorite,
                  onTap: () => context.push('/catalog/${product.id}'),
                  onFavoriteTap: () => context.read<FavoriteCubit>().toggleFavorite(product.id),
                );
              },
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildScrollableBody(ProductState state) {
    if (state is ProductError) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().loadCatalog(),
            ),
          ),
        ],
      );
    }

    if (state is ProductLoading || state is ProductInitial || state is ProductDetailLoaded) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverGrid(
              gridDelegate: DamosCatalogProductGridShimmer.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (_, __) => const LoadingShimmer(
                  width: DamosCatalogProductCard.cardWidth,
                  height: DamosCatalogProductCard.cardHeight,
                  borderRadius: 8,
                ),
                childCount: 6,
              ),
            ),
          ),
        ],
      );
    }

    if (state is ProductCatalogLoaded) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: _buildCategorySection(state.selectedCategoryId, state.categories),
          ),
          _buildProductGridSliver(state),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductCatalogLoaded) {
            return RefreshIndicator(
              color: DamosDominanceColors.primary,
              onRefresh: () async {
                await context.read<ProductCubit>().loadCatalog(
                      categoryId: state.selectedCategoryId,
                      search: state.searchQuery,
                    );
              },
              child: _buildScrollableBody(state),
            );
          }

          return RefreshIndicator(
            color: DamosDominanceColors.primary,
            onRefresh: () => context.read<ProductCubit>().loadCatalog(),
            child: _buildScrollableBody(state),
          );
        },
      ),
    );
  }
}
