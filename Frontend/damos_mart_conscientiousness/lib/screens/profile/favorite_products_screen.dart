import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color bgPage = Color(0xFFFCF8F8);
  static const Color red = Color(0xFFD32F2F);
}

class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({super.key});

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  final FavoriteRepository _repository = FavoriteRepository();

  List<ProductModel>? _products;
  String? _errorMessage;
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _products = null;
      _errorMessage = null;
      _selectedIds.clear();
    });
    try {
      final products = await _repository.getFavorites();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memuat produk favorit. Coba lagi ya!');
    }
  }

  void _toggleItem(String id) =>
      setState(() => _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id));

  void _toggleAll(bool? select) {
    setState(() {
      if (select == true) {
        _selectedIds
          ..clear()
          ..addAll((_products ?? []).map((p) => p.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      PopUpAlert.show(
        context: context,
        title: 'Belum Ada yang Dipilih',
        description: 'Pilih produk yang ingin dihapus dari favorit terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isDeleting = true);
    final ids = _selectedIds.toList();
    for (final id in ids) {
      try {
        await _repository.removeFavorite(id);
        if (mounted) context.read<FavoriteCubit>().removeLocally(id);
      } catch (_) {
        // Continue removing the rest even if one call fails.
      }
    }

    if (!mounted) return;
    setState(() {
      _products = (_products ?? []).where((p) => !ids.contains(p.id)).toList();
      _selectedIds.clear();
      _isDeleting = false;
    });
  }

  Widget _buildSelectAllBar(List<ProductModel> products) {
    final isAllChecked = products.isNotEmpty && _selectedIds.length == products.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isAllChecked,
              activeColor: _Ds.primary,
              side: const BorderSide(color: _Ds.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: products.isEmpty ? null : (v) => _toggleAll(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pilih Semua (${_selectedIds.length})',
              style: const TextStyle(fontSize: 13, color: _Ds.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: _isDeleting ? null : _deleteSelected,
            child: _isDeleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _Ds.red),
                  )
                : const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Ds.red),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductModel product) {
    final isSelected = _selectedIds.contains(product.id);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isSelected,
              activeColor: _Ds.primary,
              side: const BorderSide(color: _Ds.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => _toggleItem(product.id),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/catalog/${product.id}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 60,
                height: 60,
                color: _Ds.bgGrey,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
                      )
                    : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/catalog/${product.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: _Ds.red, size: 20),
            onPressed: () async {
              try {
                await _repository.removeFavorite(product.id);
                if (!mounted) return;
                context.read<FavoriteCubit>().removeLocally(product.id);
                setState(() {
                  _products = (_products ?? []).where((p) => p.id != product.id).toList();
                  _selectedIds.remove(product.id);
                });
              } catch (_) {
                if (!mounted) return;
                PopUpAlert.show(
                  context: context,
                  title: 'Gagal',
                  description: 'Gagal menghapus dari favorit. Coba lagi ya!',
                  isError: true,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: _Ds.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Produk Favorit',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Ds.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ketuk ikon hati pada produk untuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Jelajahi Katalog'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _products ?? [];

    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(title: 'Favorit Produk', showBackButton: true),
          if (_products != null && products.isNotEmpty) ...[
            _buildSelectAllBar(products),
            const Divider(height: 1, color: _Ds.borderLight),
          ],
          Expanded(
            child: _errorMessage != null
                ? ErrorState(message: _errorMessage!, onRetry: _load)
                : _products == null
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, __) => const LoadingShimmer(
                          width: double.infinity,
                          height: 84,
                          borderRadius: 8,
                        ),
                      )
                    : products.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _Ds.primary,
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildProductItem(products[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
