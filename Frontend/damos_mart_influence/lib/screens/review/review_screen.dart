import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/product/product_cubit.dart';
import '../../config/api_config.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/review_repository.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color star = Color(0xFFFFC107);
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth = 1.5;

  _DashedBorderPainter({
    required this.color,
    this.borderRadius = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String productId;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.productId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  ProductModel? _currentProduct(ProductState state) {
    if (state is ProductDetailLoaded && state.product.id == widget.productId) {
      return state.product;
    }
    return null;
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) {
      PopUpAlert.show(
        context: context,
        title: 'Batas Maksimal',
        description: 'Maksimal 3 foto dapat diunggah.',
        isError: true,
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Memilih Foto',
        description: 'Tidak dapat membuka galeri foto. Berikan izin akses ya!',
        isError: true,
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      PopUpAlert.show(
        context: context,
        title: 'Rating Belum Dipilih',
        description: 'Pilih bintang untuk memberi rating produk.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ReviewRepository();
      await repository.submitReview(
        orderId: widget.orderId,
        productId: widget.productId,
        rating: _rating,
        comment: _commentController.text.trim(),
        localPhotoPaths: _selectedPhotos.map((file) => file.path).toList(),
      );

      if (mounted) {
        PopUpAlert.showSuccess(
          context: context,
          title: 'Ulasan Terkirim',
          description: 'Terima kasih atas penilaian Anda.',
          onConfirm: () => context.go('/home'),
        );
      }
    } catch (e) {
      if (mounted) {
        PopUpAlert.show(
          context: context,
          title: 'Gagal Mengirim',
          description: 'Ulasan gagal terkirim. Coba lagi nanti ya!',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProductInfoCard(ProductModel? product, bool isLoading) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: const Row(
          children: [
            LoadingShimmer(width: 50, height: 50, borderRadius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(width: 140, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  LoadingShimmer(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final name = product?.name ?? 'Produk';
    final category = product?.categoryName.isNotEmpty == true ? product!.categoryName : 'Kategori';
    final imageUrl = product?.imageUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _Ds.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image_outlined, color: _Ds.textSecondary, size: 22),
                    )
                  : const Icon(Icons.image_outlined, color: _Ds.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _Ds.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = _rating >= starIndex;

        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
          child: GestureDetector(
            onTap: () => setState(() => _rating = starIndex),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 40,
              color: isFilled ? _Ds.star : _Ds.borderLight,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: _Ds.border, borderRadius: 10),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 22, color: _Ds.textSecondary),
              SizedBox(height: 4),
              Text('Upload', style: TextStyle(fontSize: 10, color: _Ds.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _selectedPhotos[index],
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: _Ds.textPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollContent(ProductModel? product, bool productLoading) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosPageHeader(
            title: 'Beri Rating Produk',
            showBackButton: true,
            backgroundColor: Colors.white,
            foregroundColor: _Ds.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          _buildProductInfoCard(product, productLoading),
          const SizedBox(height: 28),
          const Text(
            'Bagaimana kualitas produk ini?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildStarRating(),
          const SizedBox(height: 4),
          const Text(
            'Pilih bintang untuk memberi rating',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 28),
          const Text(
            'Ulasan Anda',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 5,
            style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tulis ulasan...',
              hintStyle: const TextStyle(fontSize: 14, color: _Ds.textSecondary),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _Ds.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _Ds.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _Ds.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tambahkan Foto (Opsional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_selectedPhotos.isNotEmpty) ...[
                for (var i = 0; i < _selectedPhotos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _buildPhotoThumbnail(i),
                ],
                if (_selectedPhotos.length < 3) const SizedBox(width: 8),
              ],
              if (_selectedPhotos.length < 3) _buildUploadBox(),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Maksimal 3 foto. Format JPG atau PNG.',
                  style: TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, productState) {
          final product = _currentProduct(productState);
          final productLoading = productState is ProductLoading;

          return Column(
            children: [
              Expanded(child: _buildScrollContent(product, productLoading)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Ds.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Kirim Ulasan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
