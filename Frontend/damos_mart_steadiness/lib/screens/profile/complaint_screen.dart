import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/complaint/complaint_cubit.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/complaint_display_utils.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_subject_option.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../../widgets/common/steadiness_app_header.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color screenBg = Color(0xFFF5F5F5);
}

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  static const int _minDetailLength = 20;
  static const int _maxDetailLength = 500;
  static const int _maxPhotoBytes = 2 * 1024 * 1024;

  final _detailController = TextEditingController();
  final _imagePicker = ImagePicker();

  ComplaintSubjectOption? _selectedSubject;
  bool _subjectExpanded = false;
  String? _detailError;
  String? _subjectError;
  Uint8List? _photoBytes;
  String? _photoName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintCubit>().loadComplaints();
    });
    _detailController.addListener(_onDetailChanged);
  }

  void _onDetailChanged() {
    if (!mounted || _detailError == null) return;
    final text = _detailController.text.trim();
    if (text.length >= _minDetailLength) {
      setState(() => _detailError = null);
    }
  }

  @override
  void dispose() {
    _detailController.removeListener(_onDetailChanged);
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        if (!mounted) return;
        PopUpAlert.show(
          context: context,
          title: 'Ukuran File Terlalu Besar',
          description: 'Bukti foto maksimal 2MB.',
          isError: true,
        );
        return;
      }

      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
      });
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

  void _clearForm() {
    setState(() {
      _selectedSubject = null;
      _subjectExpanded = false;
      _detailError = null;
      _subjectError = null;
      _photoBytes = null;
      _photoName = null;
      _detailController.clear();
    });
  }

  Future<void> _submit() async {
    final detail = _detailController.text.trim();

    setState(() {
      _subjectError = _selectedSubject == null ? 'Pilih subjek keluhan terlebih dahulu' : null;
      _detailError = null;
    });

    if (_selectedSubject == null) return;

    if (detail.isEmpty) {
      setState(() => _detailError = 'Detail masalah harus diisi');
      return;
    }

    if (detail.length < _minDetailLength) {
      setState(() {
        _detailError = 'Detail masalah minimal $_minDetailLength karakter';
      });
      return;
    }

    try {
      final created = await context.read<ComplaintCubit>().submitComplaint(
            subject: _selectedSubject!.label,
            description: detail,
            category: _selectedSubject!.apiCategory,
          );
      if (!mounted || created == null) return;

      final photoBytes = _photoBytes;
      _clearForm();

      context.push(
        '/profile/chat/complaints/${created.id}/track',
        extra: {
          'complaint': created,
          if (photoBytes != null) 'photoBytes': photoBytes,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      PopUpAlert.show(
        context: context,
        title: 'Gagal Mengirim Komplain',
        description: e.message,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.screenBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SteadinessAppHeader(),
          Expanded(
            child: BlocBuilder<ComplaintCubit, ComplaintState>(
              builder: (context, state) {
                if (state is ComplaintLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _Ds.primary),
                  );
                }

                if (state is ComplaintError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => context.read<ComplaintCubit>().loadComplaints(),
                  );
                }

                final complaints = state is ComplaintLoaded ? state.complaints : <ComplaintModel>[];
                final isSubmitting = state is ComplaintLoaded && state.isSubmitting;

                return RefreshIndicator(
                  color: _Ds.primary,
                  onRefresh: () => context.read<ComplaintCubit>().loadComplaints(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormCard(isSubmitting),
                        const SizedBox(height: 24),
                        _buildHistoryHeader(),
                        const SizedBox(height: 12),
                        if (complaints.isEmpty)
                          _buildEmptyHistory()
                        else
                          ...complaints.map(_buildHistoryCard),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Buat Komplain',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _Ds.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sampaikan keluhan Anda terkait layanan atau produk kami.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _Ds.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Subjek Keluhan'),
          const SizedBox(height: 8),
          _buildSubjectDropdown(),
          _inlineError(_subjectError),
          const SizedBox(height: 16),
          _fieldLabel('Detail Masalah'),
          const SizedBox(height: 8),
          TextField(
            controller: _detailController,
            maxLines: 5,
            maxLength: _maxDetailLength,
            style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
            decoration: InputDecoration(
              hintText: 'Jelaskan secara rinci permasalahan Anda...',
              hintStyle: const TextStyle(fontSize: 13, color: _Ds.hint),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _detailError != null ? ComplaintDisplayColors.rejectedRed : _Ds.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _detailError != null ? ComplaintDisplayColors.rejectedRed : _Ds.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          _inlineError(_detailError),
          const SizedBox(height: 16),
          _fieldLabel('Bukti Foto (Opsional)'),
          const SizedBox(height: 8),
          _buildPhotoPicker(),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Ds.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
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
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _Ds.textPrimary,
      ),
    );
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
          color: ComplaintDisplayColors.rejectedRed,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() => _subjectExpanded = !_subjectExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _subjectError != null ? ComplaintDisplayColors.rejectedRed : _Ds.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSubject?.label ?? 'Pilih Subjek',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedSubject == null ? _Ds.hint : _Ds.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _subjectExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _Ds.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_subjectExpanded) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            shadowColor: const Color(0x1A000000),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: Column(
              children: ComplaintSubjectOption.values.map((option) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubject = option;
                      _subjectExpanded = false;
                      _subjectError = null;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF3F4F6)),
                      ),
                    ),
                    child: Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _Ds.textSecondary,
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

  Widget _buildPhotoPicker() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _Ds.border,
        radius: 12,
        dashWidth: 6,
        dashGap: 4,
      ),
      child: InkWell(
        onTap: _pickPhoto,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            children: [
              if (_photoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _photoBytes!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.photo_camera_outlined,
                  size: 36,
                  color: _Ds.hint,
                ),
              const SizedBox(height: 10),
              Text(
                _photoName ?? 'Klik untuk unggah foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _photoName == null ? _Ds.textSecondary : _Ds.textPrimary,
                  fontWeight: _photoName == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Riwayat Komplain',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _Ds.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.read<ComplaintCubit>().loadComplaints(),
          style: TextButton.styleFrom(
            foregroundColor: _Ds.textSecondary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Semua',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.border),
      ),
      child: const Text(
        'Belum ada riwayat komplain.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
      ),
    );
  }

  Widget _buildHistoryCard(ComplaintModel complaint) {
    final footerMeta = ComplaintDisplayUtils.footerMeta(complaint);
    final footerColor = ComplaintDisplayUtils.footerMetaColor(complaint);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(
          '/profile/chat/complaints/${complaint.id}/track',
          extra: {'complaint': complaint},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Ds.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    complaint.ticketNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _Ds.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(complaint.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.subject,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _Ds.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ComplaintDisplayUtils.snippet(complaint.description),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _Ds.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ComplaintDisplayUtils.formatDateTime(complaint.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Ds.hint,
                      ),
                    ),
                  ),
                  if (footerMeta != null)
                    Flexible(
                      child: Text(
                        footerMeta,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: footerColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ComplaintStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ComplaintDisplayUtils.statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ComplaintDisplayUtils.statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ComplaintDisplayUtils.statusTextColor(status),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extractPath, paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
