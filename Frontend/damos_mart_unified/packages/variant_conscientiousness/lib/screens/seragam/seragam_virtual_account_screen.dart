import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_cubit.dart';
import '../../data/models/order_model.dart';

// Static state untuk reminder banner di katalog seragam
class SeragamPendingOrder {
  static OrderModel? pendingOrder;
  static String? pendingBank;
}

// Tracker daftar pesanan seragam (lacak pesanan)
class SeragamOrderTracker {
  static final List<OrderModel> orders = [];
  static void addOrder(OrderModel o) {
    if (!orders.any((e) => e.id == o.id)) orders.insert(0, o);
  }
}

class SeragamVirtualAccountScreen extends StatefulWidget {
  final OrderModel order;
  final String bank;
  const SeragamVirtualAccountScreen({super.key, required this.order, required this.bank});

  @override
  State<SeragamVirtualAccountScreen> createState() => _SeragamVirtualAccountScreenState();
}

class _SeragamVirtualAccountScreenState extends State<SeragamVirtualAccountScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _green10 = Color(0xFFDCF5E0);
  static const Color _border  = Color(0xFFCCCCCC);

  late int _secondsLeft;
  Timer? _timer;
  bool _hasPaid = false;
  Set<String> _expandedInstructions = {};
  OrderModel? _updatedOrder; // order hasil payOrder() dengan status PAID

  @override
  void initState() {
    super.initState();
    _secondsLeft = 59 * 60; // 59 menit
    // Simpan sebagai pending order untuk reminder
    SeragamPendingOrder.pendingOrder = widget.order;
    SeragamPendingOrder.pendingBank  = widget.bank;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _vaNumber {
    final base = widget.order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0');
    switch (widget.bank) {
      case 'BNI':     return '8800 0812 ${base.substring(0,4)} 7890';
      case 'BRI':     return '8888 0812 ${base.substring(0,4)} 7890';
      case 'BCA':     return '8067 0812 ${base.substring(0,4)} 7890';
      case 'MANDIRI': return '8881 0812 ${base.substring(0,4)} 7890';
      default:        return '8000 0812 ${base.substring(0,4)} 7890';
    }
  }

  String get _bankLabel {
    switch (widget.bank) {
      case 'BNI':     return 'Bank BNI';
      case 'BRI':     return 'Bank BRI';
      case 'BCA':     return 'Bank BCA';
      case 'MANDIRI': return 'Bank Mandiri';
      default:        return 'Bank';
    }
  }

  String get _timerStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '00:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Map<String, List<String>> get _instructions => {
    'm-${widget.bank == 'BCA' ? 'BCA' : widget.bank} (Mobile Banking)': [
      'Masuk ke Akun ${_bankLabel} Mobile app.',
      'Pilih m-Transfer lalu ${widget.bank} Virtual Account',
      'Masukan Nomer Virtual Account',
      'Ikuti langkah-langkah ini untuk menyelesaikan transaksi',
    ],
    'ATM ${widget.bank}': [
      'Masuk ke menu Transfer di ATM.',
      'Pilih Virtual Account.',
      'Masukkan nomor VA: ${_vaNumber.replaceAll(' ', '')}',
      'Konfirmasi nominal dan selesaikan transaksi.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderDetailLoaded && state.order.id == widget.order.id) {
          // Tangkap order ter-update (status PAID) dari payOrder()
          setState(() => _updatedOrder = state.order);
        }
      },
      child: Scaffold(
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
                  const Text('Selesaikan Pembayaran',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),

                  // Timer card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selesaikan Pembayaran Dalam',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70)),
                            Text(_timerStr,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                        const Icon(Icons.access_time, color: Color(0xFFFFC107), size: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // VA Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _green10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border)),
                              alignment: Alignment.center,
                              child: Text(widget.bank.substring(0, 3),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: _dark)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_bankLabel,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                                const Text('Virtual Account',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Virtual Account',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_vaNumber,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _dark)),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _vaNumber.replaceAll(' ', '')));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nomor VA disalin'), duration: Duration(seconds: 1)));
                              },
                              child: const Icon(Icons.copy_outlined, size: 22, color: _primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        const Text('Total Amount',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _grey)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(CurrencyFormatter.format(widget.order.total),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _dark)),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.order.total.toStringAsFixed(0)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Jumlah disalin'), duration: Duration(seconds: 1)));
                              },
                              child: const Icon(Icons.copy_outlined, size: 22, color: _primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simulasi pembayaran button
                  if (!_hasPaid)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                  setState(() => _hasPaid = true);
                  // Kirim payOrder ke backend agar status jadi PAID otomatis
                  context.read<OrderCubit>().payOrder(widget.order.id, paymentMethod: 'QRIS');
                },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Simulasikan Pembayaran Di Sini',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _green10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primary),
                      ),
                      alignment: Alignment.center,
                      child: const Text('✓ Pembayaran Berhasil Disimulasikan',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
                    ),
                  const SizedBox(height: 20),

                  // Instruksi Pembayaran
                  const Text('Instruksi Pembayaran',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                  const SizedBox(height: 10),
                  ..._instructions.entries.map((e) => _buildAccordion(e.key, e.value)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Cek status button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasPaid ? () {
                        SeragamPendingOrder.pendingOrder = null;
                        SeragamPendingOrder.pendingBank  = null;
                        final finalOrder = _updatedOrder ?? widget.order;
                        SeragamOrderTracker.addOrder(finalOrder);
                        context.go('/checkout/success', extra: finalOrder);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _grey,
                        elevation: 0,
                        side: _hasPaid ? BorderSide.none : const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cek Status Pembayaran',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pembayaran akan terverifikasi secara otomatis dalam 1-2 menit setelah transaksi berhasil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF888888), height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            onPressed: () => context.go('/seragam'), // langsung ke katalog seragam, reminder aktif
          ),
          const Text('Kembali Ke Katalog',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAccordion(String title, List<String> steps) {
    final isOpen = _expandedInstructions.contains(title);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (isOpen) _expandedInstructions.remove(title);
              else _expandedInstructions.add(title);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: _grey, size: 20),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $s',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _grey, height: 1.4)),
                    )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
