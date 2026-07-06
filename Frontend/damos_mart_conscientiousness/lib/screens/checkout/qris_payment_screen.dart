import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/order/order_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../widgets/common/pop_up_alert.dart';
import '../seragam/seragam_virtual_account_screen.dart' show SeragamPendingOrder, SeragamOrderTracker;

class QrisPaymentScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;
  final bool fromSeragam;

  const QrisPaymentScreen({
    super.key,
    required this.orderId,
    this.order,
    this.fromSeragam = false,
  });

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  static const Color _primary = Color(0xFF018D1A);
  static const Color _bg      = Color(0xFFFCF8F8);
  static const Color _dark    = Color(0xFF111111);
  static const Color _grey    = Color(0xFF555555);
  static const Color _border  = Color(0xFFCCCCCC);
  static const Color _green10 = Color(0xFFE8F5E9);

  OrderModel? _order;
  bool _hasPaid    = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      context.read<OrderCubit>().loadOrderDetail(widget.orderId);
    }
    // Simpan sebagai pending jika dari seragam
    if (widget.fromSeragam && widget.order != null) {
      SeragamPendingOrder.pendingOrder = widget.order;
    }
  }

  String _qrData() {
    final o = _order;
    if (o == null) return 'DAMOS-MART';
    return 'DAMOS-MART|${o.orderNumber}|${o.total.toStringAsFixed(0)}|NMID:ID1023304672596';
  }

  void _simulatePayment() {
    if (_hasPaid) return;
    setState(() => _hasPaid = true);
    PopUpAlert.showAddedToCart(
        context: context, productName: 'QRIS Berhasil dibayar');
  }

  void _downloadQr() {
    PopUpAlert.showAddedToCart(
        context: context, productName: 'QrCode Berhasil di unduh');
  }

  Future<void> _cekStatus() async {
    if (!_hasPaid || _isVerifying || _order == null) return;
    setState(() => _isVerifying = true);
    await context.read<OrderCubit>().payOrder(
          _order!.id,
          paymentMethod: 'QRIS',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded && _order == null) {
            setState(() => _order = state.order);
          }
          if (state is OrderDetailLoaded && _isVerifying) {
            context.read<CartCubit>().loadCart();
            SeragamPendingOrder.pendingOrder = null;
            if (widget.fromSeragam) {
              SeragamOrderTracker.addOrder(state.order);
            }
            context.go('/checkout/success', extra: state.order);
          }
          if (state is OrderError && _isVerifying) {
            setState(() => _isVerifying = false);
            PopUpAlert.show(
              context: context,
              title: 'Pembayaran Gagal',
              description: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          if (_order == null) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selesaikan Pembayaran',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),

                // ── QR Code box ──
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _hasPaid ? null : _simulatePayment,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _qrData(),
                                version: QrVersions.auto,
                                size: 220,
                                gapless: true,
                                eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF111111)),
                                dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF111111)),
                              ),
                              if (_hasPaid)
                                Container(
                                  width: 220,
                                  height: 220,
                                  color: Colors.white.withOpacity(0.7),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.check_circle,
                                      color: Color(0xFF018D1A), size: 64),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hasPaid
                              ? 'Pembayaran berhasil!'
                              : 'Klik QRIS untuk simulasi pembayaran',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _hasPaid ? _primary : _grey,
                            fontWeight: _hasPaid
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Download QR button ──
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _downloadQr,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download QR',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Instruksi Pembayaran ──
                const Text('Instruksi Pembayaran',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 12),
                _buildStep(1, 'Buka aplikasi Bank/e-wallet pilihan Anda (GOPAY, OVO, Dana, LinkAja, dll).'),
                const SizedBox(height: 8),
                _buildStep(2, 'Pilih menu "Scan" atau "Bayar" dan arahkan kamera ke kode QR di atas.'),
                const SizedBox(height: 8),
                _buildStep(3, 'Konfirmasi nominal pembayaran dan masukkan PIN keamanan Anda.'),
                const SizedBox(height: 24),

                // ── Cek Status button ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _hasPaid && !_isVerifying ? _cekStatus : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      disabledBackgroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: _grey,
                      elevation: 0,
                      side: _hasPaid
                          ? BorderSide.none
                          : const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Cek Status Pembayaran',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pembayaran akan terverifikasi secara otomatis dalam 1-2 menit setelah transaksi berhasil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF888888),
                      height: 1.4),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _primary,
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (!_isVerifying) {
                if (widget.fromSeragam) {
                  context.go('/seragam'); // ke katalog seragam, reminder aktif
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              }
            },
          ),
          const Text('Kembali Ke Beranda',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _green10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: _primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$number',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _dark,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
