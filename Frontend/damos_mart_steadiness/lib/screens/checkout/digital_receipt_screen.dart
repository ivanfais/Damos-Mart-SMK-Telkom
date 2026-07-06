import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/receipt_display_utils.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color primaryDark = Color(0xFF157024);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color successBg = Color(0xFFE8F5E9);
}

class DigitalReceiptScreen extends StatefulWidget {
  const DigitalReceiptScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DigitalReceiptScreen> createState() => _DigitalReceiptScreenState();
}

class _DigitalReceiptScreenState extends State<DigitalReceiptScreen> {
  final OrderRepository _orderRepository = OrderRepository();

  OrderModel? _order;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderRepository.getOrderDetails(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyTransactionId(OrderModel order) {
    final id = ReceiptDisplayUtils.transactionId(order);
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID transaksi disalin.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bg,
      body: Column(
        children: [
          const SteadinessTitleHeader(title: 'Struk Digital'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ProductGridShimmer(itemCount: 2),
      );
    }

    if (_errorMessage != null || _order == null) {
      return ErrorState(
        message: _errorMessage ?? 'Gagal memuat struk.',
        onRetry: () {
          setState(() => _isLoading = true);
          _loadOrder();
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        children: [
          _ReceiptCard(
            order: _order!,
            onCopyTransactionId: () => _copyTransactionId(_order!),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.order,
    required this.onCopyTransactionId,
  });

  final OrderModel order;
  final VoidCallback onCopyTransactionId;

  @override
  Widget build(BuildContext context) {
    final adminFee = ReceiptDisplayUtils.adminFee(order);
    final isPaid = order.paymentStatus == PaymentStatus.paid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ReceiptHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                if (isPaid) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Ds.successBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Ds.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: _Ds.primary),
                        SizedBox(width: 6),
                        Text(
                          'Pembayaran Berhasil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _Ds.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  CurrencyFormatter.format(order.total),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _Ds.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ReceiptDisplayUtils.formatPaidAt(order),
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _DashedDivider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Column(
              children: [
                _MetaRow(
                  label: 'ID Transaksi',
                  value: ReceiptDisplayUtils.transactionId(order),
                  onCopy: onCopyTransactionId,
                ),
                _MetaRow(
                  label: 'Nomor Antrean',
                  value: ReceiptDisplayUtils.queueLabel(order),
                ),
                _MetaRow(label: 'Jenis Pesanan', value: ReceiptDisplayUtils.orderTypeLabel(order)),
                _MetaRow(
                  label: 'Metode Pembayaran',
                  value: ReceiptDisplayUtils.paymentMethodLabel(order),
                ),
                _MetaRow(
                  label: 'Status Pembayaran',
                  value: ReceiptDisplayUtils.paymentStatusLabel(order),
                  valueColor: isPaid ? _Ds.primary : _Ds.textSecondary,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _DashedDivider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Item',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Ds.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                for (final item in order.orderItems) _ReceiptItemRow(item: item),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _DashedDivider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(order.subtotal)),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Biaya Admin', value: CurrencyFormatter.format(adminFee)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _Ds.border),
                ),
                _SummaryRow(
                  label: 'Total Bayar',
                  value: CurrencyFormatter.format(order.total),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const _ReceiptFooter(),
        ],
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_Ds.primary, _Ds.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              AppConstants.imageLogo,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'DAMOS MART',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            AppConstants.schoolName,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'STRUK DIGITAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptFooter extends StatelessWidget {
  const _ReceiptFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      color: _Ds.bg,
      child: Column(
        children: [
          const _DashedDivider(),
          const SizedBox(height: 14),
          const Text(
            'Terima kasih telah berbelanja\ndi Koperasi Siswa Damos Mart',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _Ds.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dicetak ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.now().toLocal())}',
            style: const TextStyle(fontSize: 10, color: _Ds.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onCopy,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _Ds.textSecondary),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? _Ds.textPrimary,
                    ),
                  ),
                ),
                if (onCopy != null)
                  GestureDetector(
                    onTap: onCopy,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.copy_rounded, size: 16, color: _Ds.primary),
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

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final variant = item.variantName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Ds.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (variant != null && variant.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(variant, style: const TextStyle(fontSize: 11, color: _Ds.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${CurrencyFormatter.format(item.productPrice)}',
                  style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _Ds.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? _Ds.primary : _Ds.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: isTotal ? _Ds.primary : _Ds.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              color: _Ds.border,
            );
          }),
        );
      },
    );
  }
}
