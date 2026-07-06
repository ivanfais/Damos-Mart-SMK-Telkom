import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../widgets/catalog/catalog_product_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color chipBg = Color(0xFFEEEEEE);
  static const Color red = Color(0xFFD42427);
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductCubit>().loadMore();
    }
  }

  void _triggerSearch(String query) {
    context.read<ProductCubit>().searchProducts(query.trim());
  }

  List<CategoryModel> _sortedCategories(List<CategoryModel> categories) {
    return [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _Ds.primary : _Ds.chipBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _Ds.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String selectedCategoryId, List<CategoryModel> categories) {
    final sortedCategories = _sortedCategories(categories);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          controller: _categoryScrollController,
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sortedCategories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCategoryChip(
                label: 'Semua',
                isSelected: selectedCategoryId.isEmpty,
                onTap: () => context.read<ProductCubit>().filterByCategory(''),
              );
            }

            final category = sortedCategories[index - 1];
            return _buildCategoryChip(
              label: category.name,
              isSelected: selectedCategoryId == category.id,
              onTap: () => context.read<ProductCubit>().filterByCategory(category.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChipsShimmer() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 88,
          decoration: BoxDecoration(
            color: _Ds.chipBg,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
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

  Widget _buildHeader() {
    return SteadinessAppHeader(
      bottom: SteadinessSearchBar(
        controller: _searchController,
        onSubmitted: _triggerSearch,
      ),
    );
  }

  Widget _buildProductGrid(ProductCatalogLoaded state) {
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverGrid(
        gridDelegate: ProductGridLayout.catalogGridDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.products.length) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: _Ds.primary),
                  ),
                ),
              );
            }

            final product = state.products[index];
            return CatalogProductCard(
              product: product,
              onTap: () => context.push('/catalog/${product.id}'),
              onBuy: () => _addToCart(product),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildBody(ProductState state) {
    if (state is ProductError) {
      return Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ErrorState(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().loadCatalog(),
            ),
          ),
        ],
      );
    }

    if (state is ProductLoading || state is ProductInitial || state is ProductDetailLoaded) {
      return Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildCategoryChipsShimmer(),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ProductGridShimmer(itemCount: 4, catalog: true),
          ),
        ],
      );
    }

    return Column(children: [_buildHeader()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.background,
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
            return Column(
              children: [
                _buildHeader(),
                _buildCategoryChips(state.selectedCategoryId, state.categories),
                Expanded(
                  child: RefreshIndicator(
                    color: _Ds.primary,
                    onRefresh: () async {
                      await context.read<ProductCubit>().loadCatalog(
                            categoryId: state.selectedCategoryId,
                            search: state.searchQuery,
                          );
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildProductGrid(state),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: _Ds.primary,
            onRefresh: () => context.read<ProductCubit>().loadCatalog(),
            child: _buildBody(state),
          );
        },
      ),
    );
  }
}
