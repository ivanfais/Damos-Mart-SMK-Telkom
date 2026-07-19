import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color red = Color(0xFFD42427);
  static const Color bgLight = Color(0xFFF9F9F9);
}

class QRTicketScreen extends StatefulWidget {
  final String queueId;

  const QRTicketScreen({super.key, required this.queueId});

  @override
  State<QRTicketScreen> createState() => _QRTicketScreenState();
}

class _QRTicketScreenState extends State<QRTicketScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadQueueDetail(widget.queueId);
  }

  Widget _buildQrContainer(String data) {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Ds.textPrimary, width: 3),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _Ds.textPrimary, width: 2),
        ),
        child: Center(
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: 168,
            gapless: true,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _Ds.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _Ds.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String queueNumber, String qrData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'NOMOR ANTREAN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Ds.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              queueNumber,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: _Ds.red,
                height: 1,
              ),
            ),
            const SizedBox(height: 28),
            _buildQrContainer(qrData),
            const SizedBox(height: 28),
            const Text(
              'Tunjukkan kode QR ini ke petugas kasir untuk pengambilan pesanan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _Ds.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingShimmer(width: 140, height: 14, borderRadius: 4),
            SizedBox(height: 8),
            LoadingShimmer(width: 120, height: 56, borderRadius: 8),
            SizedBox(height: 28),
            LoadingShimmer(width: 220, height: 220, borderRadius: 16),
            SizedBox(height: 28),
            LoadingShimmer(width: double.infinity, height: 14, borderRadius: 4),
            SizedBox(height: 8),
            LoadingShimmer(width: 260, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollPage(Widget child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DamosPageHeader(
            title: AppConstants.appName,
            showBackButton: true,
            leadingIcon: Icons.close,
            onBack: () => context.pop(),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgLight,
      body: BlocBuilder<QueueCubit, QueueState>(
        builder: (context, state) {
          if (state is QueueLoading) {
            return _buildScrollPage(_buildShimmerLoading());
          }

          if (state is QueueError) {
            return _buildScrollPage(
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<QueueCubit>().loadQueueDetail(widget.queueId),
                ),
              ),
            );
          }

          if (state is QueueDetailLoaded) {
            final queue = state.queue;
            return _buildScrollPage(_buildContent(queue.queueNumber, queue.id));
          }

          return _buildScrollPage(
            const SizedBox(
              height: 240,
              child: Center(child: Text('Memuat tiket QR...')),
            ),
          );
        },
      ),
    );
  }
}
