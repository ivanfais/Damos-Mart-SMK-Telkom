import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../data/models/category_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/catalog/damos_catalog_product_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/favorites/damos_favorites_category_chips.dart';
import '../../widgets/favorites/damos_favorites_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FavoriteCubit>().loadFavorites();
    context.read<CartCubit>().loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    final state = context.read<FavoriteCubit>().state;
    final categoryId =
        state is FavoriteListLoaded ? state.selectedCategoryId : '';
    context.read<FavoriteCubit>().loadFavorites(
          categoryId: categoryId,
          search: query.trim(),
        );
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
    return DamosFavoritesHeader(
      searchController: _searchController,
      onSearchSubmitted: _triggerSearch,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
    );
  }

  Widget _buildCategorySection(String selectedCategoryId, List<CategoryModel> categories) {
    final sortedCategories = _sortedCategories(categories);
    final chipLabels = _chipLabelsFor(categories);
    final selectedChip = _selectedChipLabel(selectedCategoryId, categories);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: DamosFavoritesCategoryChips(
        labels: chipLabels,
        selectedLabel: selectedChip,
        onSelected: (label) {
          final categoryId = label == 'Semua'
              ? ''
              : sortedCategories.where((c) => c.name == label).firstOrNull?.id ?? '';
          context.read<FavoriteCubit>().loadFavorites(
                categoryId: categoryId,
                search: _searchController.text.trim(),
              );
        },
      ),
    );
  }

  Widget _buildProductGrid(FavoriteListLoaded state) {
    if (state.products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            emoji: '❤️',
            title: 'Belum ada produk favorit',
            subtitle: 'Tandai produk dengan ikon love untuk menyimpannya di sini.',
            actionButtonText: 'Jelajahi Katalog',
            onActionButtonPressed: () => context.go('/catalog'),
          ),
        ),
      );
    }

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
            final product = state.products[index];
            return DamosCatalogProductCard(
              product: product,
              isFavorite: true,
              onTap: () => context.push('/catalog/${product.id}'),
              onFavoriteTap: () => context.read<FavoriteCubit>().toggleFavorite(product.id),
            );
          },
          childCount: state.products.length,
        ),
      ),
    );
  }

  Widget _buildBody(FavoriteState state) {
    if (state is FavoriteError) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: state.message,
              onRetry: () => context.read<FavoriteCubit>().loadFavorites(),
            ),
          ),
        ],
      );
    }

    if (state is FavoriteListLoading || state is FavoriteIdsLoaded) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: DamosFavoritesCategoryChips(
                labels: const ['Semua'],
                selectedLabel: 'Semua',
                onSelected: (_) {},
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 24,
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

    if (state is FavoriteListLoaded) {
      if (_searchController.text != state.searchQuery) {
        _searchController.text = state.searchQuery;
      }

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: _buildCategorySection(state.selectedCategoryId, state.categories),
          ),
          _buildProductGrid(state),
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
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: DamosDominanceColors.primary,
            onRefresh: () async {
              if (state is FavoriteListLoaded) {
                await context.read<FavoriteCubit>().loadFavorites(
                      categoryId: state.selectedCategoryId,
                      search: state.searchQuery,
                    );
              } else {
                await context.read<FavoriteCubit>().loadFavorites();
              }
            },
            child: _buildBody(state),
          );
        },
      ),
    );
  }
}
