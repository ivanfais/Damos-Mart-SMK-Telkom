import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/order_model.dart';
import '../../data/models/complaint_category_option.dart';
import '../../data/repositories/order_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComplaintProductSelectionScreen extends StatefulWidget {
  const ComplaintProductSelectionScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<ComplaintProductSelectionScreen> createState() =>
      _ComplaintProductSelectionScreenState();
}

class _ComplaintProductSelectionScreenState
    extends State<ComplaintProductSelectionScreen> {
  static const _cardRadius = 8.0;

  final _orderRepository = OrderRepository();

  OrderModel? _order;
  bool _loading = true;
  String? _error;

  String? _selectedProductId;
  String? _selectedServiceId;

  bool get _hasSelection =>
      _selectedProductId != null || _selectedServiceId != null;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await _orderRepository.getOrderDetails(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _selectProduct(String productId) {
    setState(() {
      _selectedProductId = productId;
      _selectedServiceId = null;
    });
  }

  void _selectService(String serviceId) {
    setState(() {
      _selectedServiceId = serviceId;
      _selectedProductId = null;
    });
  }

  void _continue() {
    if (!_hasSelection || _order == null) return;

    final extra = <String, dynamic>{
      'orderId': widget.orderId,
      'orderNumber': _order!.orderNumber,
      'orderItems': _order!.orderItems.map((e) => e.toJson()).toList(),
    };

    if (_selectedProductId != null) {
      final item = _order!.orderItems.firstWhere((e) => e.id == _selectedProductId);
      extra['selectedProduct'] = item.toJson();
    } else if (_selectedServiceId != null) {
      extra['serviceIssueId'] = _selectedServiceId;
    }

    context.push('/orders/${widget.orderId}/complaints/form', extra: extra);
  }

  Widget _productThumbnail(String? imageUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: DamosDominanceColors.fieldFill,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ApiConfig.imageUrl(imageUrl),
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(
                Icons.image_outlined,
                color: DamosDominanceColors.textSecondary,
              ),
            )
          : const Icon(
              Icons.image_outlined,
              color: DamosDominanceColors.textSecondary,
            ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DamosDominanceColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: DamosDominanceColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DamosDominanceColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            const DamosPageHeader(
              title: 'Pilih Produk',
              showBackButton: true,
              backgroundColor: DamosDominanceColors.primary,
            ),
            const Expanded(
              child: DamosListCardShimmer(),
            ),
          ],
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            const DamosPageHeader(
              title: 'Pilih Produk',
              showBackButton: true,
              backgroundColor: DamosDominanceColors.primary,
            ),
            Expanded(
              child: ErrorState(
                message: _error ?? 'Pesanan tidak ditemukan',
                onRetry: _loadOrder,
              ),
            ),
          ],
        ),
      );
    }

    final orderItems = _order!.orderItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Pilih Produk',
            showBackButton: true,
            backgroundColor: DamosDominanceColors.primary,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DamosDominanceColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 36,
                      color: DamosDominanceColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Produk mana yang bermasalah?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih produk yang ingin Anda komplain agar kami dapat membantu lebih tepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(
                          icon: Icons.inventory_2_outlined,
                          title: 'Ada masalah dengan produk?',
                          subtitle: 'Pilih barang dari pesanan ini',
                        ),
                        const Divider(height: 1, color: DamosDominanceColors.fieldBorder),
                        ...List.generate(orderItems.length, (index) {
                          final item = orderItems[index];
                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _selectProduct(item.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      _productThumbnail(item.imageUrl),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: DamosDominanceColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.displaySubtitle,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: DamosDominanceColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: item.id,
                                        groupValue: _selectedProductId,
                                        activeColor: DamosDominanceColors.primary,
                                        onChanged: (_) => _selectProduct(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < orderItems.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: DamosDominanceColors.fieldBorder,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(
                          icon: Icons.list_alt_outlined,
                          title: 'Atau masalah dengan proses pesanan?',
                        ),
                        const Divider(height: 1, color: DamosDominanceColors.fieldBorder),
                        ...List.generate(ComplaintServiceIssueOption.values.length, (index) {
                          final option = ComplaintServiceIssueOption.values[index];
                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _selectService(option.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: DamosDominanceColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          option.icon,
                                          size: 20,
                                          color: DamosDominanceColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: DamosDominanceColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              option.subtitle,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: DamosDominanceColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: option.id,
                                        groupValue: _selectedServiceId,
                                        activeColor: DamosDominanceColors.primary,
                                        onChanged: (_) => _selectService(option.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < ComplaintServiceIssueOption.values.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: DamosDominanceColors.fieldBorder,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: DamosDominanceColors.fieldBorder)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasSelection ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSelection
                        ? DamosDominanceColors.primary
                        : DamosDominanceColors.buttonDisabledFill,
                    foregroundColor: _hasSelection
                        ? Colors.white
                        : DamosDominanceColors.buttonDisabledText,
                    disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                    disabledForegroundColor: DamosDominanceColors.buttonDisabledText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                  ),
                  child: const Text(
                    'Lanjut',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
