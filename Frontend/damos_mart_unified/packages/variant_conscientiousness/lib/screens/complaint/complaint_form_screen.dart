import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/order/order_cubit.dart';
import '../../config/api_config.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../core/network/api_exception.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/pop_up_alert.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth = 1.5;

  _DashedBorderPainter({required this.color, this.borderRadius = 10});

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
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  static const _seragamKeywords = ['seragam', 'baju', 'kemeja', 'batik', 'pramuka', 'olahraga', 'pakaian'];

  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];

  OrderModel? _selectedOrder;
  ComplaintReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadMyOrders();
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isSeragamOrder(OrderModel order) {
    final notes = order.notes?.toLowerCase() ?? '';
    if (notes.contains('seragam') || notes.contains('transfer bank')) return true;
    return order.orderItems.any((i) {
      final name = i.productName.toLowerCase();
      return _seragamKeywords.any((kw) => name.contains(kw));
    });
  }

  bool get _canSubmit =>
      _selectedOrder != null &&
      _selectedReason != null &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedPhotos.isNotEmpty &&
      !_isSubmitting;

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (image != null) {
        setState(() => _selectedPhotos.add(image));
      }
    } catch (_) {
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
    setState(() => _selectedPhotos.removeAt(index));
  }

  void _pickOrder(List<OrderModel> completedOrders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Pilih Pesanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
              ),
              if (completedOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada pesanan selesai yang bisa dikomplain.',
                    style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: completedOrders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _Ds.borderLight),
                    itemBuilder: (context, index) {
                      final order = completedOrders[index];
                      final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _Ds.bgGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: firstItem?.imageUrl != null && firstItem!.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ApiConfig.imageUrl(firstItem.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
                                )
                              : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
                        ),
                        title: Text(
                          firstItem?.productName ?? 'Produk',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                        ),
                        subtitle: Text(
                          order.orderNumber,
                          style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                        ),
                        onTap: () {
                          setState(() => _selectedOrder = order);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pickReason() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ComplaintReason.values.map((reason) {
              return ListTile(
                title: Text(
                  reason.label,
                  style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
                ),
                onTap: () {
                  setState(() => _selectedReason = reason);
                  Navigator.of(sheetContext).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);
    try {
      final complaint = await ComplaintRepository().submitComplaint(
        orderId: _selectedOrder!.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        photos: _selectedPhotos,
      );

      if (mounted) {
        context.pushReplacement('/complaint/success', extra: complaint);
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'Laporan gagal terkirim. Coba lagi nanti ya!';
        PopUpAlert.show(
          context: context,
          title: 'Gagal Mengirim',
          description: message,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSelectorField({
    required String label,
    required String value,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder ? _Ds.textSecondary : _Ds.textPrimary,
                  fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _Ds.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelector(List<OrderModel> completedOrders) {
    final order = _selectedOrder;
    if (order == null) {
      return _buildSelectorField(
        label: 'Pilih Pesanan',
        value: 'Pilih Pesanan',
        isPlaceholder: true,
        onTap: () => _pickOrder(completedOrders),
      );
    }

    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    return GestureDetector(
      onTap: () => _pickOrder(completedOrders),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _Ds.bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: firstItem?.imageUrl != null && firstItem!.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(firstItem.imageUrl!),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: _Ds.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstItem?.productName ?? 'Produk',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _Ds.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: _Ds.border, borderRadius: 10),
        child: const SizedBox(
          width: 76,
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 22, color: _Ds.textSecondary),
              SizedBox(height: 4),
              Text('Unggah', style: TextStyle(fontSize: 11, color: _Ds.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return CustomPaint(
      painter: _DashedBorderPainter(color: _Ds.borderLight, borderRadius: 10),
      child: const SizedBox(width: 76, height: 76),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return FutureBuilder<Uint8List>(
      future: _selectedPhotos[index].readAsBytes(),
      builder: (context, snapshot) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: snapshot.hasData
                    ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                    : const ColoredBox(color: _Ds.bgGrey),
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
                  decoration: const BoxDecoration(color: _Ds.textPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          final completedOrders = state is OrderHistoryLoaded
              ? state.orders.where((o) => o.status == OrderStatus.completed && !_isSeragamOrder(o)).toList()
              : <OrderModel>[];

          return Column(
            children: [
              const DamosPageHeader(title: 'Komplain & Retur', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Pesanan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: _Ds.borderLight),
                      const SizedBox(height: 8),
                      _buildOrderSelector(completedOrders),
                      const SizedBox(height: 24),
                      const Text(
                        'Alasan Pengajuan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: _Ds.borderLight),
                      const SizedBox(height: 8),
                      _buildSelectorField(
                        label: 'Alasan Pengajuan',
                        value: _selectedReason?.label ?? 'Pilih Alasan',
                        isPlaceholder: _selectedReason == null,
                        onTap: _pickReason,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Deskripsi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: _Ds.borderLight),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Jelaskan detail masalah...',
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Unggah Media',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                          ),
                          Text(
                            'Maks 3 Foto',
                            style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: _Ds.borderLight),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(3, (index) {
                          Widget slot;
                          if (index < _selectedPhotos.length) {
                            slot = _buildPhotoThumbnail(index);
                          } else if (index == _selectedPhotos.length) {
                            slot = _buildUploadBox();
                          } else {
                            slot = _buildEmptySlot();
                          }
                          return Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                            child: slot,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Minimal 1 foto sebagai bukti.',
                        style: TextStyle(fontSize: 12, color: _Ds.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Ds.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Kirim Formulir',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'permintaan akan ditinjau oleh Tim Koperasi dalam waktu 24-48 jam. '
                        'Harap simpan kemasan asli untuk pengambilan retur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _Ds.textSecondary, height: 1.4),
                      ),
                    ],
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
