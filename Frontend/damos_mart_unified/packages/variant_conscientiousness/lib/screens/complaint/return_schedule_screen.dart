import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../core/network/api_exception.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/pop_up_alert.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ReturnScheduleScreen extends StatefulWidget {
  final ComplaintModel? initialComplaint;

  const ReturnScheduleScreen({super.key, this.initialComplaint});

  @override
  State<ReturnScheduleScreen> createState() => _ReturnScheduleScreenState();
}

class _ReturnScheduleScreenState extends State<ReturnScheduleScreen> {
  final ComplaintRepository _repository = ComplaintRepository();

  List<ComplaintModel>? _complaints;
  String? _loadError;
  ComplaintModel? _selectedComplaint;
  DateTime? _selectedDate;
  ReturnTimeSlot? _selectedSlot;
  bool _isSubmitting = false;

  bool get _isApproved => _selectedComplaint?.status == ComplaintStatus.resolved;

  bool get _canSubmit =>
      _selectedComplaint != null &&
      _isApproved &&
      _selectedDate != null &&
      _selectedSlot != null &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _selectedComplaint = widget.initialComplaint;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _complaints = null;
      _loadError = null;
    });
    try {
      final complaints = await _repository.getMyComplaints();
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        if (_selectedComplaint != null) {
          final match = complaints.where((c) => c.id == _selectedComplaint!.id);
          if (match.isNotEmpty) _selectedComplaint = match.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Gagal memuat tiket laporan. Coba lagi ya!');
    }
  }

  void _pickTicket() {
    final complaints = _complaints ?? [];
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
                  'Pilih ID Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
              ),
              if (complaints.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada laporan komplain.',
                    style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: complaints.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _Ds.borderLight),
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          complaint.productName ?? 'Produk',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                        ),
                        subtitle: Text(
                          '${complaint.orderNumber ?? '-'} • ${complaint.complaintNumber}',
                          style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedComplaint = complaint;
                            _selectedDate = null;
                            _selectedSlot = null;
                          });
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

  Future<void> _pickDate() async {
    if (!_isApproved) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final schedule = await _repository.scheduleReturn(
        complaintId: _selectedComplaint!.id,
        returnDate: _selectedDate!,
        timeSlot: _selectedSlot!,
      );
      if (mounted) {
        context.pushReplacement('/complaint/return-schedule/success', extra: schedule);
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'Gagal menjadwalkan pengembalian. Coba lagi ya!';
        PopUpAlert.show(context: context, title: 'Gagal', description: message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTicketSelector() {
    final complaint = _selectedComplaint;
    if (complaint == null) {
      return GestureDetector(
        onTap: _pickTicket,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Ds.border),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text('Pilih ID Laporan', style: TextStyle(fontSize: 14, color: _Ds.textSecondary)),
              ),
              Icon(Icons.keyboard_arrow_down, color: _Ds.textSecondary),
            ],
          ),
        ),
      );
    }

    final isRejected = complaint.status == ComplaintStatus.rejected;
    final badgeLabel = isRejected
        ? 'Pengajuan Ditolak'
        : complaint.status == ComplaintStatus.resolved
            ? 'Pengajuan Disetujui'
            : 'Menunggu Peninjauan';
    final badgeBg = complaint.status == ComplaintStatus.resolved ? _Ds.primary : _Ds.bgGrey;
    final badgeText = complaint.status == ComplaintStatus.resolved ? Colors.white : _Ds.textSecondary;

    return GestureDetector(
      onTap: _pickTicket,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.productName ?? 'Produk',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
            ),
            const SizedBox(height: 6),
            Text('#${complaint.orderNumber ?? '-'}', style: const TextStyle(fontSize: 13, color: _Ds.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint.complaintNumber,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeText),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: _Ds.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final enabled = _isApproved;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : _Ds.bgGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _Ds.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'DD/MM/YYYY',
                style: TextStyle(
                  fontSize: 15,
                  color: enabled ? _Ds.textPrimary : _Ds.textSecondary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 20, color: enabled ? _Ds.textPrimary : _Ds.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(ReturnTimeSlot slot) {
    final enabled = _isApproved;
    final selected = _selectedSlot == slot;

    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedSlot = slot) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? (selected ? _Ds.greenLight : Colors.white) : _Ds.bgGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? (selected ? _Ds.primary : _Ds.textPrimary) : _Ds.bgGrey, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? _Ds.textPrimary : _Ds.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.timeRange,
                    style: TextStyle(fontSize: 13, color: enabled ? _Ds.textSecondary : const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            if (enabled && selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: _Ds.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(title: 'Komplain & Retur', showBackButton: true),
          Expanded(
            child: _loadError != null
                ? ErrorState(message: _loadError!, onRetry: _load)
                : _complaints == null
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoadingShimmer(width: 200, height: 20, borderRadius: 4),
                            SizedBox(height: 16),
                            LoadingShimmer(width: double.infinity, height: 80, borderRadius: 10),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jadwalkan Pengembalian',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: _Ds.borderLight),
                            const SizedBox(height: 16),
                            _buildTicketSelector(),
                            const SizedBox(height: 24),
                            const Text(
                              'Pilih Jadwal',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: _Ds.borderLight),
                            const SizedBox(height: 16),
                            const Text(
                              'Tanggal Pengembalian',
                              style: TextStyle(fontSize: 14, color: _Ds.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            _buildDateField(),
                            const SizedBox(height: 20),
                            const Text(
                              'Jam Tersedia',
                              style: TextStyle(fontSize: 14, color: _Ds.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ...ReturnTimeSlot.values.map(_buildSlotCard),
                          ],
                        ),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _Ds.bgGrey,
                    disabledForegroundColor: _Ds.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Jadwalkan Pengembalian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
