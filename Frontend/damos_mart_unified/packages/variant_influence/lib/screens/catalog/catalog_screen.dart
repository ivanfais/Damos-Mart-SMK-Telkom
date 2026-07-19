import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../widgets/common/damos_screen_header.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../widgets/product/damos_product_grid_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color border = Color(0xFFD1D5DB);
  static const Color red = Color(0xFFD42427);
}

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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

  String _selectedChipLabel(String selectedCategoryId, List<CategoryModel> categories) {
    if (selectedCategoryId.isEmpty) return 'Semua Produk';
    return categories
            .where((c) => c.id == selectedCategoryId)
            .firstOrNull
            ?.name ??
        'Semua Produk';
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

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _Ds.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _Ds.primary : _Ds.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _Ds.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String selectedCategoryId, List<CategoryModel> categories) {
    final sortedCategories = _sortedCategories(categories);
    final chipLabels = ['Semua Produk', ...sortedCategories.map((c) => c.name)];
    final selectedChip = _selectedChipLabel(selectedCategoryId, categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Kategori',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: chipLabels.map((label) {
              final isSelected = selectedChip == label;
              return _buildCategoryChip(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  if (label == 'Semua Produk') {
                    context.read<ProductCubit>().filterByCategory('');
                    return;
                  }
                  final category =
                      sortedCategories.where((c) => c.name == label).firstOrNull;
                  context.read<ProductCubit>().filterByCategory(category?.id ?? '');
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
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
            title: 'Produk tidak ditemukan 😔',
            subtitle: 'Coba cari dengan kata kunci lain ya!',
            actionButtonText: 'Reset Filter 🔁',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: ProductGridLayout.responsiveSliverDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.products.length) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE5E7EB)),
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
            return DamosProductGridCard(
              product: product,
              onTap: () {
                if (product.isPreorder) {
                  context.push('/preorder/${product.id}');
                } else {
                  context.push('/catalog/${product.id}');
                }
              },
              onAddToCart: () => _addToCart(product),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildScrollableBody(ProductState state) {
    if (state is ProductError) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DamosScreenHeader(
              searchController: _searchController,
              onSearchSubmitted: _triggerSearch,
            ),
            ErrorState(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().loadCatalog(),
            ),
          ],
        ),
      );
    }

    if (state is ProductLoading || state is ProductInitial || state is ProductDetailLoaded) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DamosScreenHeader(
              searchController: _searchController,
              onSearchSubmitted: _triggerSearch,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Kategori',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ProductGridShimmer(),
            ),
          ],
        ),
      );
    }

    if (state is ProductCatalogLoaded) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: DamosScreenHeader(
              searchController: _searchController,
              onSearchSubmitted: _triggerSearch,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCategorySection(state.selectedCategoryId, state.categories),
          ),
          _buildProductGridSliver(state),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: DamosScreenHeader(
        searchController: _searchController,
        onSearchSubmitted: _triggerSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              color: _Ds.primary,
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
            color: _Ds.primary,
            onRefresh: () => context.read<ProductCubit>().loadCatalog(),
            child: _buildScrollableBody(state),
          );
        },
      ),
    );
  }
}
