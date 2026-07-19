import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/order_model.dart';

class SeragamBankSelectionScreen extends StatefulWidget {
  final OrderModel order;
  const SeragamBankSelectionScreen({super.key, required this.order});

  @override
  State<SeragamBankSelectionScreen> createState() => _SeragamBankSelectionScreenState();
}

class _SeragamBankSelectionScreenState extends State<SeragamBankSelectionScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);
  static const Color _green10 = Color(0xFFDCF5E0);

  static const _banks = [
    _BankOption(id: 'BNI',     name: 'BNI',     label: 'Virtual Account BNI'),
    _BankOption(id: 'BRI',     name: 'BRI',     label: 'Virtual Account BRI'),
    _BankOption(id: 'BCA',     name: 'BCA',     label: 'Virtual Account BCA'),
    _BankOption(id: 'MANDIRI', name: 'Mandiri', label: 'Virtual Account Mandiri'),
  ];

  String? _selectedBank;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Bank',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),
                  ..._banks.map((bank) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildBankOption(bank),
                      )),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/seragam'),
          ),
          const Text('Transfer Bank',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBankOption(_BankOption bank) {
    final sel = _selectedBank == bank.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedBank = bank.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? _green10 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? _primary : _border, width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              alignment: Alignment.center,
              child: Text(bank.name,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bank.name,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                  Text(bank.label,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                ],
              ),
            ),
            // Radio
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? _primary : _border, width: 2)),
              child: sel ? Center(child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle))) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _selectedBank == null ? null : () {
              context.push('/seragam-va', extra: {
                'order': widget.order,
                'bank': _selectedBank!,
              });
            },
            icon: const Icon(Icons.payment_outlined, size: 20),
            label: const Text('Lanjutkan Pembayaran',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              disabledBackgroundColor: _primary.withOpacity(0.4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankOption {
  final String id, name, label;
  const _BankOption({required this.id, required this.name, required this.label});
}
