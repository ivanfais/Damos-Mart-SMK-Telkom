import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgPage = Color(0xFFFCF8F8);
}

class ComplaintTicketPickerScreen extends StatefulWidget {
  const ComplaintTicketPickerScreen({super.key});

  @override
  State<ComplaintTicketPickerScreen> createState() => _ComplaintTicketPickerScreenState();
}

class _ComplaintTicketPickerScreenState extends State<ComplaintTicketPickerScreen> {
  final ComplaintRepository _repository = ComplaintRepository();

  List<ComplaintModel>? _complaints;
  String? _errorMessage;
  ComplaintModel? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _complaints = null;
      _errorMessage = null;
    });
    try {
      final complaints = await _repository.getMyComplaints();
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        if (complaints.isNotEmpty) _selected = complaints.first;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memuat tiket laporan. Coba lagi ya!');
    }
  }

  void _pickTicket(List<ComplaintModel> complaints) {
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
                  'Pilih Tiket Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                ),
              ),
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
                        setState(() => _selected = complaint);
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

  Widget _buildTicketSelector(List<ComplaintModel> complaints) {
    final selected = _selected;
    if (selected == null) {
      return GestureDetector(
        onTap: () => _pickTicket(complaints),
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
                child: Text(
                  'Belum ada tiket laporan',
                  style: TextStyle(fontSize: 14, color: _Ds.textSecondary),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: _Ds.textSecondary),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _pickTicket(complaints),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.productName ?? 'Produk',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected.orderNumber ?? '-',
                    style: const TextStyle(fontSize: 13, color: _Ds.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.complaintNumber,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Ds.textSecondary),
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

  Widget _buildBody() {
    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }

    if (_complaints == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(width: 160, height: 18, borderRadius: 4),
            SizedBox(height: 16),
            LoadingShimmer(width: double.infinity, height: 76, borderRadius: 10),
          ],
        ),
      );
    }

    final complaints = _complaints!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Tiket Laporan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
          ),
          const SizedBox(height: 8),
          const Divider(color: _Ds.borderLight),
          const SizedBox(height: 16),
          _buildTicketSelector(complaints),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: _Ds.bgPage,
      body: Column(
        children: [
          const DamosPageHeader(title: 'Komplain & Retur', showBackButton: true),
          Expanded(child: SingleChildScrollView(child: _buildBody())),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () => context.push('/complaint/status', extra: selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Ds.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _Ds.primary.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Lihat Status',
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
