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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final productCubit = context.read<ProductCubit>();
    final state = productCubit.state;
    if (state is ProductCatalogLoaded) {
      _searchController.text = state.searchQuery;
    } else if (state is! ProductLoading) {
      productCubit.loadCatalog();
    }

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductCubit>().loadMore();
    }
  }

  void _triggerSearch(String query) {
    context.read<ProductCubit>().searchProducts(query.trim());
  }

  List<CategoryModel> _sortedCategories(List<CategoryModel> categories) {
    return [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<String> _chipLabelsFor(List<CategoryModel> categories) {
    final sorted = _sortedCategories(categories);
    return ['Semua', ...sorted.map((c) => c.name)];
  }

  String _selectedChipLabel(String selectedCategoryId, List<CategoryModel> categories) {
    if (selectedCategoryId.isEmpty) return 'Semua';
    return categories
            .where((c) => c.id == selectedCategoryId)
            .firstOrNull
            ?.name ??
        'Semua';
  }

  Widget _buildHeader() {
    return DamosCatalogHeader(
      searchController: _searchController,
      onSearchSubmitted: _triggerSearch,
    );
  }

  Widget _buildCategorySection(String selectedCategoryId, List<CategoryModel> categories) {
    final sortedCategories = _sortedCategories(categories);
    final chipLabels = _chipLabelsFor(categories);
    final selectedChip = _selectedChipLabel(selectedCategoryId, categories);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: DamosCatalogCategoryChips(
        chipLabels: chipLabels,
        selectedLabel: selectedChip,
        onSelected: (label) {
          if (label == 'Semua') {
            context.read<ProductCubit>().filterByCategory('');
            return;
          }
          final category =
              sortedCategories.where((c) => c.name == label).firstOrNull;
          context.read<ProductCubit>().filterByCategory(category?.id ?? '');
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
              _searchController.clear();
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
              return SizedBox(
                width: DamosCatalogProductCard.cardWidth,
                height: DamosCatalogProductCard.cardHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DamosDominanceColors.primary,
                      ),
                    ),
                  ),
                ),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              child: SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: DamosDominanceColors.primary,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: DamosCatalogProductCard.cardHeight,
              ),
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
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductCatalogLoaded) {
            if (_searchController.text != state.searchQuery) {
              _searchController.text = state.searchQuery;
            }
          }
        },
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
