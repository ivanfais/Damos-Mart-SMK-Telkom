import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';

class SeragamPreorderInfoScreen extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? variant;
  final int quantity;

  const SeragamPreorderInfoScreen({
    super.key,
    required this.product,
    required this.variant,
    required this.quantity,
  });

  @override
  State<SeragamPreorderInfoScreen> createState() => _SeragamPreorderInfoScreenState();
}

class _SeragamPreorderInfoScreenState extends State<SeragamPreorderInfoScreen> {
  static const Color _primary  = Color(0xFF018D1A);
  static const Color _bg       = Color(0xFFFCF8F8);
  static const Color _dark     = Color(0xFF111111);
  static const Color _grey     = Color(0xFF555555);
  static const Color _border   = Color(0xFFCCCCCC);
  static const Color _green10  = Color(0xFFDCF5E0);

  final _nameCtrl  = TextEditingController();
  final _kelasCtrl = TextEditingController();

  bool get _canConfirm =>
      _nameCtrl.text.trim().isNotEmpty && _kelasCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kelasCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const m = ['Januari','Februari','Maret','April','Mei','Juni',
                'Juli','Agustus','September','Oktober','November','Desember'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  int _productionDays() {
    final est = widget.product.preorderEstimation ?? '';
    final nums = RegExp(r'(\d+)').allMatches(est).map((m) => int.parse(m.group(1)!)).toList();
    return nums.isEmpty ? 14 : nums.reduce((a, b) => a > b ? a : b);
  }

  DateTime _addBizDays(DateTime start, int days) {
    var r = start; var added = 0;
    while (added < days) {
      r = r.add(const Duration(days: 1));
      if (r.weekday != DateTime.saturday && r.weekday != DateTime.sunday) added++;
    }
    return r;
  }

  double get _price =>
      widget.product.price + (widget.variant?.additionalPrice ?? 0);

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final days    = _productionDays();
    final arrival = _addBizDays(now, days);
    final raw     = widget.product.preorderEstimation ?? '';
    final estProd = raw.trim().isEmpty ? '$days Hari Kerja' : raw;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informasi Pemesan ──
                  Row(
                    children: const [
                      Icon(Icons.info, size: 22, color: _dark),
                      SizedBox(width: 8),
                      Text('Informasi Pemesan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Nama Lengkap'),
                  const SizedBox(height: 6),
                  _buildField(_nameCtrl, 'Masukkan nama siswa'),
                  const SizedBox(height: 12),

                  _fieldLabel('Kelas'),
                  const SizedBox(height: 6),
                  _buildField(_kelasCtrl, 'Contoh: 10 IPA 1'),
                  const SizedBox(height: 24),

                  // ── Rincian Pesanan ──
                  const Text('Rincian Pesanan',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80, height: 80,
                            color: const Color(0xFFF0F0F0),
                            child: widget.product.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: ApiConfig.imageUrl(widget.product.imageUrl!),
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.checkroom_outlined, color: Color(0xFFCCCCCC)))
                                : const Icon(Icons.checkroom_outlined, color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.product.name,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _dark)),
                              const SizedBox(height: 4),
                              if (widget.variant != null)
                                Text('Size : ${widget.variant!.variantName}',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Qty : ${widget.quantity}X',
                                      style: const TextStyle(
                                          fontFamily: 'Poppins', fontSize: 13, color: _grey)),
                                  Text(CurrencyFormatter.format(_price * widget.quantity),
                                      style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _dark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Informasi Pre-Order ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, size: 18, color: _dark),
                            SizedBox(width: 6),
                            Text('INFORMASI PRE-ORDER',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _dark,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Waktu Pemesanan:', _formatDate(now)),
                        const SizedBox(height: 6),
                        _infoRow('Estimasi Produksi:', estProd),
                        const SizedBox(height: 6),
                        _infoRow('Estimasi Tiba:', _formatDate(arrival), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Button ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setBtn) {
                  _nameCtrl.addListener(() => setBtn(() {}));
                  _kelasCtrl.addListener(() => setBtn(() {}));
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _primary.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Konfirmasi Pre-Order',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onConfirm() {
    context.push('/seragam-checkout', extra: {
      'product': widget.product,
      'variant': widget.variant,
      'quantity': widget.quantity,
      'nama': _nameCtrl.text.trim(),
      'kelas': _kelasCtrl.text.trim(),
    });
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/seragam'),
          ),
          const Text('Informasi Pemesan',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _dark));

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFFBBBBBB)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _grey)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: _dark)),
        ],
      );
}
