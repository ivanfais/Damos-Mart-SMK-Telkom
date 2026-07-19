import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../config/app_constants.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/pop_up_alert.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _red      = Color(0xFFD32F2F);

  // Hanya produk seragam/pakaian yang dikecualikan (by nama produk)
  static const _excludedProductKeywords = [
    'baju', 'kemeja', 'seragam', 'batik', 'putih abu', 'pakaian', 'kaos',
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final state = context.read<ProductCubit>().state;
    if (state is ProductCatalogLoaded) {
      _searchController.text = state.searchQuery;
    } else if (state is! ProductLoading) {
      context.read<ProductCubit>().loadCatalog();
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
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final state = context.read<ProductCubit>().state;
      if (state is ProductCatalogLoaded && !state.isLoadMoreRunning) {
        final p = state.pagination;
        if (p != null && p.currentPage < p.totalPages) {
          context.read<ProductCubit>().loadMore();
        }
      }
    }
  }

  bool _isUniform(ProductModel p) {
    final name = p.name.toLowerCase();
    return _excludedProductKeywords.any((kw) => name.contains(kw));
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) =>
      products.where((p) => !_isUniform(p)).toList();

  void _onSearch(String query) =>
      context.read<ProductCubit>().searchProducts(query.trim());

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

  void _openDetail(ProductModel product) {
    context.push('/catalog/${product.id}');
  }

  Future<void> _addToCart(ProductModel product) async {
    if (product.isPreorder) { context.push('/preorder/${product.id}'); return; }
    final variantId = product.variants.isNotEmpty ? product.variants.first.id : null;
    await context.read<CartCubit>().addToCart(
        productId: product.id, variantId: variantId, quantity: 1);
    if (!mounted) return;
    final s = context.read<CartCubit>().state;
    if (s is CartError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${s.message}'), backgroundColor: _red),
      );
      return;
    }
    PopUpAlert.showAddedToCart(context: context, productName: 'Produk Ditambahkan\nKe Keranjang');
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductCatalogLoaded &&
              _searchController.text != state.searchQuery) {
            _searchController.text = state.searchQuery;
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              final cat = state is ProductCatalogLoaded
                  ? state.selectedCategoryId
                  : '';
              await context.read<ProductCubit>().loadCatalog(categoryId: cat);
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(
                  child: _buildCategorySection(state),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: const Text(
                      'Katalog Produk',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                  ),
                ),
                _buildProductSliver(state),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
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
                      fontFamily: 'Poppins', fontSize: 11, color: Colors.white70)),
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
                onSubmitted: _onSearch,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 14, color: _dark),
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(width: 1, height: 24, color: _border),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.filter_list, color: _grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORY CHIPS ───────────────────────────────────────────────────────
  Widget _buildCategorySection(ProductState state) {
    final selectedCategoryId =
        state is ProductCatalogLoaded ? state.selectedCategoryId : '';
    final categories =
        state is ProductCatalogLoaded ? state.categories : <CategoryModel>[];
    final sortedCategories = _sortedCategories(categories);
    final chipLabels = ['Semua Produk', ...sortedCategories.map((c) => c.name)];
    final selectedChip = _selectedChipLabel(selectedCategoryId, categories);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _dark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chipLabels.map((label) {
              final isSelected = selectedChip == label;
              return GestureDetector(
                onTap: () {
                  if (label == 'Semua Produk') {
                    context.read<ProductCubit>().filterByCategory('');
                    return;
                  }
                  final category =
                      sortedCategories.where((c) => c.name == label).firstOrNull;
                  context.read<ProductCubit>().filterByCategory(category?.id ?? '');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? _primary : _border, width: 1.2),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : _dark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT SLIVER ───────────────────────────────────────────────────────
  Widget _buildProductSliver(ProductState state) {
    if (state is ProductLoading || state is ProductInitial) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildShimmer(),
        ),
      );
    }

    if (state is ProductCatalogLoaded) {
      final products = _filterProducts(state.products);

      if (products.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, size: 48, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 12),
                const Text('Produk tidak ditemukan',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
                const SizedBox(height: 6),
                const Text('Coba kata kunci atau kategori lain',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductCubit>().loadCatalog();
                  },
                  child: const Text('Reset Filter',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: _primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      }

      // Build 2-column rows
      final rows = <Widget>[];
      for (var i = 0; i < products.length; i += 2) {
        final left  = products[i];
        final right = i + 1 < products.length ? products[i + 1] : null;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildProductCard(left)),
                const SizedBox(width: 10),
                Expanded(
                    child: right != null
                        ? _buildProductCard(right)
                        : const SizedBox()),
              ],
            ),
          ),
        );
        if (i + 2 < products.length) rows.add(const SizedBox(height: 10));
      }

      // Load more indicator
      if (state.isLoadMoreRunning) {
        rows.add(const SizedBox(height: 16));
        rows.add(const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
        ));
      }

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: rows),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox());
  }

  // ─── PRODUCT CARD (same style as home) ────────────────────────────────────
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
          GestureDetector(
            onTap: () => _openDetail(product),
            behavior: HitTestBehavior.opaque,
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: () {
                      final displayImageUrl = product.displayImageUrl();
                      return displayImageUrl != null && displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.imageUrl(displayImageUrl),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholder(),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder();
                    }(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _grey)),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 34,
                        child: Text(product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                                height: 1.3)),
                      ),
                      const SizedBox(height: 3),
                      Text(isAvailable ? 'Tersedia' : 'Habis',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? _primary : _red)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(product.price),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ), // end GestureDetector
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                BlocBuilder<FavoriteCubit, FavoriteState>(
                  builder: (context, favoriteState) {
                    final isFavorite =
                        context.read<FavoriteCubit>().isFavorite(product.id);
                    return GestureDetector(
                      onTap: () =>
                          context.read<FavoriteCubit>().toggleFavorite(product.id),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? _red : _grey,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      onPressed:
                          isAvailable ? () => _addToCart(product) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _grey.withOpacity(0.25),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Tambah Ke Keranjang',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
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

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF0F0F0),
        alignment: Alignment.center,
        child: const Icon(Icons.shopping_bag_outlined,
            size: 26, color: Color(0xFFCCCCCC)),
      );

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < 3 ? 10 : 0),
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
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard() => Container(
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
                Container(
                    width: 64, height: 64, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 9, width: 50, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 34, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(
                          height: 10, width: 40, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(
                          height: 12, width: 60, color: Colors.white),
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
