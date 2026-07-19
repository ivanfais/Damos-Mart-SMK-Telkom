import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/favorite/favorite_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg = Color(0xFFFCF8F8);
  static const Color _dark = Color(0xFF111111);
  static const Color _grey = Color(0xFF555555);
  static const Color _border = Color(0xFFCCCCCC);
  static const Color _red = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    context.read<FavoriteCubit>().loadFavorites();
  }

  Future<void> _addToCart(ProductModel product) async {
    if (product.isPreorder) {
      context.push('/preorder/${product.id}');
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
        SnackBar(content: Text('Gagal: ${cartState.message}'), backgroundColor: _red),
      );
      return;
    }
    PopUpAlert.showAddedToCart(
      context: context,
      productName: 'Produk Ditambahkan\nKe Keranjang',
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isAvailable = product.stock > 0 && !product.isPreorder;

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
            onTap: () => context.push('/catalog/${product.id}'),
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
                        final imageUrl = product.displayImageUrl();
                        return imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ApiConfig.imageUrl(imageUrl),
                                fit: BoxFit.cover,
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
                        Text(
                          product.categoryName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: _grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 34,
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.read<FavoriteCubit>().toggleFavorite(product.id),
                  child: const Icon(Icons.favorite, size: 18, color: _red),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      onPressed: isAvailable ? () => _addToCart(product) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _grey.withOpacity(0.25),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Tambah Ke Keranjang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
        color: const Color(0xFFF0F0F0),
        alignment: Alignment.center,
        child: const Icon(Icons.shopping_bag_outlined, size: 26, color: Color(0xFFCCCCCC)),
      );

  Widget _buildGrid(List<ProductModel> products) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      final left = products[i];
      final right = i + 1 < products.length ? products[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildProductCard(left)),
              const SizedBox(width: 10),
              Expanded(child: right != null ? _buildProductCard(right) : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < products.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          DamosPageHeader(
            title: 'Produk Favorit',
            showBackButton: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          Expanded(
            child: BlocBuilder<FavoriteCubit, FavoriteState>(
              builder: (context, state) {
                if (state is FavoriteListLoading || state is FavoriteInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                if (state is FavoriteError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => context.read<FavoriteCubit>().loadFavorites(),
                  );
                }

                if (state is FavoriteListLoaded) {
                  if (state.products.isEmpty) {
                    return EmptyState(
                      emoji: '💚',
                      title: 'Belum ada produk favorit',
                      subtitle: 'Ketuk ikon hati pada produk untuk menyimpannya di sini.',
                      actionButtonText: 'Jelajahi Katalog',
                      onActionButtonPressed: () => context.go('/catalog'),
                    );
                  }

                  return RefreshIndicator(
                    color: _primary,
                    onRefresh: () => context.read<FavoriteCubit>().loadFavorites(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [_buildGrid(state.products)],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
