import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/cooperative/cooperative_cubit.dart';
import '../../blocs/product/product_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/product_grid_layout.dart';
import '../../data/models/product_model.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE0E0E0);
  static const Color quickActionBg = Color(0xFFEEEEEE);
  static const Color red = Color(0xFFD42427);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();

  List<ProductModel> _featuredProducts = [];
  bool _isLoadingFeatured = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
    context.read<CooperativeCubit>().loadCurrentStatus();
    context.read<QueueCubit>().loadActiveQueues();
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      var products = await _productRepository.getFeaturedProducts(limit: 4);
      if (products.isEmpty) {
        final result = await _productRepository.getProducts(limit: 4, sort: 'newest');
        products = (result['products'] as List<ProductModel>?) ?? [];
      }
      if (mounted) {
        setState(() {
          _featuredProducts = products.take(4).toList();
          _isLoadingFeatured = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFeatured = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoadingFeatured = true);
    context.read<QueueCubit>().loadActiveQueues();
    context.read<CooperativeCubit>().loadCurrentStatus();
    await _loadFeaturedProducts();
  }

  int? _queueSequence(String number) {
    final match = RegExp(r'(\d+)$').firstMatch(number.trim());
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  int _remainingPeople(QueueModel queue, QueueActiveLoaded state) {
    final userSeq = _queueSequence(queue.queueNumber);
    final currentSeq = _queueSequence(state.currentServing);
    if (userSeq == null || currentSeq == null || state.currentServing == 'N/A') {
      return state.totalWaiting;
    }
    return (userSeq - currentSeq).clamp(0, 99);
  }

  double _queueProgress(int remaining, QueueStatus status) {
    if (status == QueueStatus.ready || status == QueueStatus.completed) {
      return 1.0;
    }
    if (remaining == 0) return 0.85;
    final total = remaining + 3;
    return ((total - remaining) / total).clamp(0.2, 0.85);
  }

  String _waitEstimate(QueueModel queue) {
    final minutes = queue.estimatedWaitMinutes ?? 12;
    return '~ $minutes Menit';
  }

  QueueModel? _findActiveQueue(QueueState state) {
    if (state is! QueueActiveLoaded) return null;
    for (final queue in state.activeQueues) {
      if (queue.status == QueueStatus.waiting ||
          queue.status == QueueStatus.preparing ||
          queue.status == QueueStatus.ready) {
        return queue;
      }
    }
    return null;
  }

  Color _coopStatusColor(String condition) {
    switch (condition.toUpperCase()) {
      case 'RAMAI':
        return _Ds.red;
      case 'SEPI':
        return _Ds.textSecondary;
      default:
        return _Ds.primary;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.background,
      body: Column(
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _Ds.primary,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    _buildCooperativeCard(),
                    const SizedBox(height: 20),
                    _buildQueueSection(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final firstName = authState is Authenticated
            ? authState.user.fullName.split(' ').first
            : 'Pengguna';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang,',
              style: TextStyle(fontSize: 15, color: _Ds.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Halo, $firstName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _Ds.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCooperativeCard() {
    return BlocBuilder<CooperativeCubit, CooperativeState>(
      builder: (context, state) {
        final statusLabel = state is CooperativeLoaded
            ? state.currentStatus.label
            : 'Normal';
        final statusColor = state is CooperativeLoaded
            ? _coopStatusColor(state.currentStatus.condition)
            : _Ds.primary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Ds.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_outline, color: _Ds.textSecondary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kepadatan Koperasi',
                      style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kondisi Koperasi: $statusLabel',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _Ds.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueSection() {
    return BlocBuilder<QueueCubit, QueueState>(
      builder: (context, state) {
        final queue = _findActiveQueue(state);
        final loaded = state is QueueActiveLoaded ? state : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Antrean',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Ds.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (queue != null) {
                      context.push('/queue/${queue.id}');
                    } else {
                      context.go('/queue');
                    }
                  },
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Ds.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: _Ds.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (queue != null && loaded != null)
              _buildQueueCard(queue, loaded)
            else
              _buildEmptyQueueCard(),
          ],
        );
      },
    );
  }

  Widget _buildQueueCard(QueueModel queue, QueueActiveLoaded state) {
    final remaining = _remainingPeople(queue, state);
    final progress = _queueProgress(remaining, queue.status);

    return GestureDetector(
      onTap: () async {
        await context.push('/queue/${queue.id}');
        if (!mounted) return;
        context.read<QueueCubit>().restoreActiveQueuesView();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _Ds.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NOMOR ANTREAN ANDA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Text(
                  'Estimasi Tunggu',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  queue.queueNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  _waitEstimate(queue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              remaining > 0
                  ? '$remaining Orang lagi sebelum giliran Anda'
                  : 'Giliran Anda akan segera dipanggil',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Ds.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'NOMOR ANTREAN ANDA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada antrean aktif',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beli produk di katalog untuk mendapatkan nomor antrean',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildQuickAction(Icons.grid_view, 'Katalog', () => context.go('/catalog')),
        const SizedBox(width: 10),
        _buildQuickAction(Icons.hourglass_empty, 'Antrean', () => context.go('/queue')),
        const SizedBox(width: 10),
        _buildQuickAction(Icons.checkroom_outlined, 'Seragam', () {
          context.read<ProductCubit>().searchProducts('seragam');
          context.go('/catalog');
        }),
        const SizedBox(width: 10),
        _buildQuickAction(Icons.help_outline, 'Komplain', () => context.push('/profile/chat')),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: _Ds.quickActionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: _Ds.textPrimary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Ds.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rekomendasi Produk',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _Ds.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingFeatured)
          const ProductGridShimmer(itemCount: 4)
        else if (_featuredProducts.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: const Text(
              'Belum ada rekomendasi produk',
              style: TextStyle(color: _Ds.textSecondary),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final product in _featuredProducts)
                SizedBox(
                  width: ProductGridLayout.itemWidth(context),
                  child: _HomeProductCard(
                    product: product,
                    onTap: () => context.push('/catalog/${product.id}'),
                    onBuy: () => _addToCart(product),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({
    required this.product,
    required this.onTap,
    required this.onBuy,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  static const Color _primary = _Ds.primary;
  static const Color _textPrimary = _Ds.textPrimary;
  static const Color _textSecondary = _Ds.textSecondary;
  static const Color _border = _Ds.border;
  static const Color _imageBg = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    final imageHeight = ProductGridLayout.itemWidth(context) * 0.85;
    final hasStock = product.stock > 0 || product.isPreorder;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: imageHeight,
              child: ColoredBox(
                color: _imageBg,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(product.imageUrl!),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.shopping_bag_outlined, color: _textSecondary, size: 32),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: _textSecondary, size: 32),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: hasStock ? onBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _textSecondary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Beli', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
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
}
