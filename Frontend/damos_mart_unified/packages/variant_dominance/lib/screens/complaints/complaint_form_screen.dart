import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/complaint_category_option.dart';
import '../../data/models/complaint_issue_option.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/pop_up_alert.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.selectedProduct,
    this.serviceIssue,
  });

  final String orderId;
  final String orderNumber;
  final OrderItemModel? selectedProduct;
  final ComplaintServiceIssueOption? serviceIssue;

  bool get isProductComplaint => selectedProduct != null;

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  static const int _maxMessageLength = 500;
  static const int _minMessageLength = 20;
  static const int _maxAttachmentBytes = 2 * 1024 * 1024;
  static const _cardRadius = 8.0;

  final _messageController = TextEditingController();
  final _repository = ComplaintRepository();
  final _imagePicker = ImagePicker();

  ComplaintIssueOption? _selectedIssue;
  ComplaintIssueOption? _hoveredIssue;
  bool _issueExpanded = false;
  bool _isSubmitting = false;
  XFile? _attachment;
  String? _messageError;

  bool get _isGranularProductIssue => widget.isProductComplaint;

  bool get _isGranularCooperativeIssue =>
      widget.serviceIssue?.id == 'cooperative_service';

  bool get _usesGranularIssues =>
      _isGranularProductIssue || _isGranularCooperativeIssue;

  List<ComplaintIssueOption> get _issueOptions {
    if (_isGranularProductIssue) {
      return ComplaintIssueOption.productIssues;
    }
    if (_isGranularCooperativeIssue) {
      return ComplaintIssueOption.cooperativeServiceIssues;
    }
    return ComplaintIssueOption.fromBackendCategories(
      ComplaintCategoryOption.all
          .map((c) => (label: c.label, apiCategory: c.apiCategory))
          .toList(),
    );
  }

  bool get _isFormReady =>
      _selectedIssue != null &&
      _messageController.text.trim().length >= _minMessageLength;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _selectedIssue = _defaultIssue();
  }

  ComplaintIssueOption? _defaultIssue() {
    final options = _issueOptions;
    if (options.isEmpty) return null;

    if (_isGranularProductIssue || _isGranularCooperativeIssue) {
      return options.first;
    }

    if (widget.serviceIssue != null) {
      for (final option in options) {
        if (option.apiCategory == widget.serviceIssue!.defaultCategory) {
          return option;
        }
      }
    }

    return options.first;
  }

  void _onMessageChanged() {
    if (!mounted) return;
    setState(() {
      if (_messageError != null) {
        final msg = _messageController.text.trim();
        if (_messageError == 'Kolom keluhan ini harus diisi' && msg.isNotEmpty) {
          _messageError = null;
        } else if (msg.length >= _minMessageLength) {
          _messageError = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > _maxAttachmentBytes) {
        if (!mounted) return;
        PopUpAlert.show(
          context: context,
          title: 'Ukuran File Terlalu Besar',
          description: 'Bukti pendukung maksimal 2MB.',
          isError: true,
        );
        return;
      }

      setState(() => _attachment = file);
    } catch (_) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengunggah',
        description: 'Tidak dapat membuka galeri foto.',
        isError: true,
      );
    }
  }

  String? _validationDetailMessage(ApiException e) {
    final details = e.details;
    if (details is! List || details.isEmpty) return null;
    final first = details.first;
    if (first is Map && first['message'] != null) {
      return first['message'].toString();
    }
    return null;
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();

    setState(() => _messageError = null);

    if (_selectedIssue == null) return;

    if (message.isEmpty) {
      setState(() => _messageError = 'Kolom keluhan ini harus diisi');
      return;
    }

    if (message.length < _minMessageLength) {
      setState(() {
        _messageError = 'Pesan keluhan minimal $_minMessageLength karakter';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.createComplaint(
        orderId: widget.orderId,
        issue: _selectedIssue!,
        description: message,
        photos: _attachment != null ? [_attachment!] : const [],
      );
      if (!mounted) return;

      context.go(
        '/complaints/success',
        extra: {
          'complaintId': result.id,
          'ticketNumber': result.displayTicketNumber,
          'orderId': widget.orderId,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final detailMsg = _validationDetailMessage(e);
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Komplain',
        description: detailMsg ?? e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Komplain',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _inlineError(String? message) {
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: DamosDominanceColors.error,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _selectionCard() {
    if (widget.isProductComplaint) {
      final product = widget.selectedProduct!;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: DamosDominanceColors.fieldBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_cardRadius),
              child: Container(
                width: 56,
                height: 56,
                color: DamosDominanceColors.fieldFill,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(product.imageUrl!),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk yang Dikomplain',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Qty ${product.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      'Ubah Pilihan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DamosDominanceColors.primary,
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

    final issue = widget.serviceIssue!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DamosDominanceColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            child: Icon(issue.icon, color: DamosDominanceColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DamosDominanceColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text(
                    'Ubah Pilihan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.primary,
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

  Widget _buildIssueDropdown() {
    final placeholder = _usesGranularIssues
        ? 'Pilih Jenis Kendala'
        : 'Pilih Kategori Komplain';

    return Column(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: InkWell(
            onTap: () {
              setState(() {
                _issueExpanded = !_issueExpanded;
                if (!_issueExpanded) _hoveredIssue = null;
              });
            },
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: DamosDominanceColors.fieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedIssue?.label ?? placeholder,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedIssue == null
                            ? DamosDominanceColors.textHint
                            : DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _issueExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: DamosDominanceColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_issueExpanded) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            shadowColor: const Color(0x1A000000),
            borderRadius: BorderRadius.circular(_cardRadius),
            color: Colors.white,
            child: Column(
              children: _issueOptions.map((option) {
                final isHovered = _hoveredIssue == option;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIssue = option),
                  onExit: (_) => setState(() => _hoveredIssue = null),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIssue = option;
                        _issueExpanded = false;
                        _hoveredIssue = null;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      color: isHovered
                          ? DamosDominanceColors.primary
                          : Colors.white,
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isHovered ? FontWeight.w700 : FontWeight.w500,
                          color: isHovered
                              ? Colors.white
                              : DamosDominanceColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentPicker() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: InkWell(
        onTap: _pickAttachment,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: DamosDominanceColors.fieldBorder),
          ),
          child: Column(
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 36,
                color: DamosDominanceColors.textSecondary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 10),
              Text(
                _attachment?.name ?? 'Unggah foto atau screenshot (Maks 2MB, opsional)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _attachment == null
                      ? DamosDominanceColors.textSecondary
                      : DamosDominanceColors.textPrimary,
                  fontWeight:
                      _attachment == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProductComplaint && widget.serviceIssue == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            const DamosPageHeader(
              title: 'Komplain',
              showBackButton: true,
              backgroundColor: DamosDominanceColors.primary,
            ),
            const Expanded(
              child: Center(
                child: Text('Pilihan komplain tidak valid.'),
              ),
            ),
          ],
        ),
      );
    }

    final messageLength = _messageController.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Komplain',
            showBackButton: true,
            backgroundColor: DamosDominanceColors.primary,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Formulir Komplain',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sampaikan kendala Anda secara detail agar kami dapat membantu lebih cepat.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _selectionCard(),
                  const SizedBox(height: 20),
                  Text(
                    _usesGranularIssues ? 'Jenis Kendala' : 'Kategori Komplain',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildIssueDropdown(),
                  const SizedBox(height: 20),
                  Text(
                    _usesGranularIssues ? 'Deskripsi Keluhan' : 'Deskripsi Masalah',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 6,
                    maxLength: _maxMessageLength,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DamosDominanceColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Jelaskan masalahmu secara detail (minimal 20 Karakter)...',
                      hintStyle: const TextStyle(
                        color: DamosDominanceColors.textHint,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
                        borderSide: BorderSide(
                          color: _messageError != null
                              ? DamosDominanceColors.error
                              : DamosDominanceColors.fieldBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
                        borderSide: BorderSide(
                          color: _messageError != null
                              ? DamosDominanceColors.error
                              : DamosDominanceColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _inlineError(_messageError),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$messageLength/$_maxMessageLength',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DamosDominanceColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bukti Pendukung (Opsional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAttachmentPicker(),
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
                child: ElevatedButton(
                  onPressed: (_isSubmitting || !_isFormReady) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormReady
                        ? DamosDominanceColors.primary
                        : DamosDominanceColors.buttonDisabledFill,
                    foregroundColor: _isFormReady
                        ? DamosDominanceColors.textOnPrimary
                        : DamosDominanceColors.buttonDisabledText,
                    disabledBackgroundColor: DamosDominanceColors.buttonDisabledFill,
                    disabledForegroundColor: DamosDominanceColors.buttonDisabledText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Kirim Komplain',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
