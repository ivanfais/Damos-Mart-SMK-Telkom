import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/complaint_category_option.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/pop_up_alert.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  static const int _maxMessageLength = 500;
  static const int _minMessageLength = 20;
  static const int _maxAttachmentBytes = 2 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _repository = ComplaintRepository();
  final _imagePicker = ImagePicker();

  ComplaintCategoryOption? _selectedCategory;
  ComplaintCategoryOption? _hoveredCategory;
  bool _categoryExpanded = false;
  bool _isSubmitting = false;
  String? _attachmentName;
  String? _messageError;

  bool get _isFormReady {
    return _selectedCategory != null && _messageController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
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

      setState(() => _attachmentName = file.name);
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

  Future<void> _submit() async {
    final message = _messageController.text.trim();

    setState(() => _messageError = null);

    if (_selectedCategory == null) {
      return;
    }

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
        subject: _selectedCategory!.label,
        description: message,
        category: _selectedCategory!.apiCategory,
      );
      if (!mounted) return;

      context.go(
        '/complaints/success',
        extra: result.ticketNumber,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Keluhan',
        description: e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Keluhan',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _inlineError(String? message) {
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

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

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageController.text.length;

    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DamosPageHeader(
              title: 'Bantuan & Komplain',
              showBackButton: true,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Formulir Pengaduan',
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
                      const SizedBox(height: 24),
                      const Text(
                        'Kategori Pengaduan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DamosDominanceColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 20),
                      const Text(
                        'Pesan Keluhan',
                        style: TextStyle(
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
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _messageError != null
                                  ? DamosDominanceColors.error
                                  : DamosDominanceColors.fieldBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _messageError != null
                                  ? DamosDominanceColors.error
                                  : DamosDominanceColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: DamosDominanceColors.error,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: DamosDominanceColors.error,
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
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormReady
                                ? DamosDominanceColors.primary
                                : DamosDominanceColors.buttonDisabledFill,
                            foregroundColor: _isFormReady
                                ? DamosDominanceColors.textOnPrimary
                                : DamosDominanceColors.buttonDisabledText,
                            disabledBackgroundColor:
                                DamosDominanceColors.buttonDisabledFill,
                            disabledForegroundColor:
                                DamosDominanceColors.buttonDisabledText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _isFormReady
                                    ? DamosDominanceColors.primary
                                    : DamosDominanceColors.buttonDisabledBorder,
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Kirim Keluhan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              setState(() {
                _categoryExpanded = !_categoryExpanded;
                if (!_categoryExpanded) _hoveredCategory = null;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DamosDominanceColors.fieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory?.label ?? 'Pilih Kategori Pengaduan',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedCategory == null
                            ? DamosDominanceColors.textHint
                            : DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _categoryExpanded
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
        if (_categoryExpanded) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            shadowColor: const Color(0x1A000000),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Column(
              children: ComplaintCategoryOption.values.map((option) {
                final isHovered = _hoveredCategory == option;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredCategory = option),
                  onExit: (_) => setState(() => _hoveredCategory = null),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = option;
                        _categoryExpanded = false;
                        _hoveredCategory = null;
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _pickAttachment,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
                _attachmentName ?? 'Unggah foto atau screenshot (Maks 2MB)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _attachmentName == null
                      ? DamosDominanceColors.textSecondary
                      : DamosDominanceColors.textPrimary,
                  fontWeight:
                      _attachmentName == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
