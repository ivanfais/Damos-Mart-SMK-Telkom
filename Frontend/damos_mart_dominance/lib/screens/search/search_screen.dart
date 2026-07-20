import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../core/search/search_navigation.dart';
import '../../core/storage/prefs_storage.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/catalog/damos_catalog_product_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.scope = SearchScope.catalog,
    this.initialQuery,
  });

  final SearchScope scope;
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ProductRepository _productRepository = ProductRepository();
  final FavoriteRepository _favoriteRepository = FavoriteRepository();

  List<String> _history = [];
  List<ProductModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      final initial = widget.initialQuery?.trim();
      if (initial != null && initial.isNotEmpty) {
        _controller.text = initial;
        _runSearch(initial);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      _history = PrefsStorage.instance.getSearchHistory();
    });
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _controller.text = query;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    await PrefsStorage.instance.addSearchHistory(query);
    _loadHistory();

    try {
      List<ProductModel> products;
      if (widget.scope == SearchScope.favorites) {
        products = await _favoriteRepository.getFavorites(search: query);
      } else {
        final result = await _productRepository.getProducts(search: query, limit: 40);
        products = (result['products'] as List<ProductModel>?) ?? [];
      }

      if (!mounted) return;
      setState(() {
        _results = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _results = [];
      });
    }
  }

  Future<void> _removeHistoryItem(String query) async {
    await PrefsStorage.instance.removeSearchHistory(query);
    _loadHistory();
  }

  Future<void> _clearHistory() async {
    await PrefsStorage.instance.clearSearchHistory();
    _loadHistory();
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: DamosDominanceColors.textHint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              style: const TextStyle(
                fontSize: 14,
                color: DamosDominanceColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'Cari produk...',
                hintStyle: TextStyle(
                  color: DamosDominanceColors.textHint,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {
                  _hasSearched = false;
                  _results = [];
                  _errorMessage = null;
                });
                _focusNode.requestFocus();
              },
              child: const Icon(
                Icons.close,
                size: 18,
                color: DamosDominanceColors.textHint,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hasil pencarian kamu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              style: TextButton.styleFrom(
                foregroundColor: DamosDominanceColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Hapus semua',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _history.map((item) => _HistoryChip(
            label: item,
            onTap: () => _runSearch(item),
            onRemove: () => _removeHistoryItem(item),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (!_hasSearched) return const SizedBox.shrink();

    if (_isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: DamosCatalogProductCard.cardHeight,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const LoadingShimmer(
          width: DamosCatalogProductCard.cardWidth,
          height: DamosCatalogProductCard.cardHeight,
          borderRadius: 8,
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DamosDominanceColors.error),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          emoji: '🔍',
          title: 'Produk tidak ditemukan',
          subtitle: 'Coba kata kunci lain ya!',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          '${_results.length} produk ditemukan',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DamosDominanceColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: DamosCatalogProductCard.cardHeight,
          ),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final product = _results[index];
            final isFavorite = context.watch<FavoriteCubit>().isFavorite(product.id);

            return DamosCatalogProductCard(
              product: product,
              isFavorite: isFavorite,
              onTap: () => context.push('/catalog/${product.id}'),
              onFavoriteTap: () =>
                  context.read<FavoriteCubit>().toggleFavorite(product.id),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: DamosDominanceColors.textPrimary,
                    ),
                    Expanded(child: _buildSearchField()),
                  ],
                ),
              ),
              const Divider(height: 1, color: DamosDominanceColors.fieldBorder),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (!_hasSearched) _buildHistorySection(),
                    _buildResultsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DamosDominanceColors.primary, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DamosDominanceColors.primary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(2, 8, 10, 8),
              child: Icon(
                Icons.close,
                size: 16,
                color: DamosDominanceColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
