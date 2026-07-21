import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cooperative/cooperative_cubit.dart';
import '../../config/api_config.dart';
import '../../data/models/cooperative_info_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color red = Color(0xFFD42427);
}

class _ChartBarData {
  final int hour;
  final int level;

  const _ChartBarData({required this.hour, required this.level});
}

class CoopInfoScreen extends StatefulWidget {
  const CoopInfoScreen({super.key});

  @override
  State<CoopInfoScreen> createState() => _CoopInfoScreenState();
}

class _CoopInfoScreenState extends State<CoopInfoScreen> {
  static const _chartHours = [8, 9, 10, 11, 12, 13, 14, 15, 16];

  @override
  void initState() {
    super.initState();
    context.read<CooperativeCubit>().loadCooperativeInfo();
  }

  CooperativeInfoModel? _infoByType(List<CooperativeInfoModel> items, String type) {
    for (final item in items) {
      if (item.infoType == type) return item;
    }
    return null;
  }

  List<_ChartBarData> _chartBars(List<CrowdDataModel> crowdData) {
    final today = DateTime.now().weekday;
    final todayCrowd = crowdData.where((c) => c.dayOfWeek == today).toList();

    return _chartHours.map((hour) {
      final match = todayCrowd.where((c) => c.hourSlot == hour).toList();
      final level = match.isNotEmpty ? match.first.avgCrowdLevel : _defaultLevel(hour);
      return _ChartBarData(hour: hour, level: level);
    }).toList();
  }

  int _defaultLevel(int hour) {
    if (hour >= 11 && hour <= 13) return 5;
    if (hour == 10 || hour == 14) return 3;
    return 2;
  }

  bool _isBusyHour(int hour, int level) {
    return (hour >= 11 && hour <= 13) || level >= 4;
  }

  String _crowdStatus(CooperativeStatusModel status) {
    return status.label;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ramai':
        return _Ds.red;
      case 'Sepi':
        return const Color(0xFF6B7280);
      default:
        return _Ds.primary;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Ds.textPrimary),
    );
  }

  Widget _buildHistoryCard(CooperativeInfoModel? aboutInfo) {
    const fallbackText =
        'Damos Mart adalah koperasi siswa SMK Telkom Jakarta yang berdiri sebagai wadah pembelajaran kewirausahaan praktis bagi siswa. Kami menyediakan berbagai macam makanan sehat, minuman segar, alat tulis berkualitas, serta atribut resmi sekolah dengan pelayanan digital yang cepat.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 160,
              color: _Ds.bgGrey,
              child: aboutInfo?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConfig.imageUrl(aboutInfo!.imageUrl!),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.storefront_outlined, size: 48, color: _Ds.textSecondary),
                    )
                  : const Icon(Icons.storefront_outlined, size: 48, color: _Ds.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            aboutInfo?.content ?? fallbackText,
            style: const TextStyle(fontSize: 14, color: _Ds.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationImage(CooperativeInfoModel? locationInfo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 180,
        color: _Ds.bgGrey,
        child: locationInfo?.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(locationInfo!.imageUrl!),
                fit: BoxFit.cover,
                placeholder: (_, __) => const DamosImagePlaceholderShimmer(),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.map_outlined, size: 48, color: _Ds.textSecondary),
              )
            : const Icon(Icons.map_outlined, size: 48, color: _Ds.textSecondary),
      ),
    );
  }

  Widget _buildLocationRow(CooperativeInfoModel? locationInfo) {
    final subtitle = locationInfo?.content.split(',').first.trim() ?? 'Lobby Lantai 1';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, size: 20, color: _Ds.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
              ),
              const SizedBox(height: 2),
              const Text(
                'SMK Telkom Jakarta',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCrowdStatusRow(String status) {
    final color = _statusColor(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('Kondisi Koperasi'),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDensityChart(List<_ChartBarData> bars) {
    final maxLevel = bars.fold<int>(1, (max, bar) => bar.level > max ? bar.level : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rata-rata kepadatan Damos Mart',
            style: TextStyle(fontSize: 13, color: _Ds.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                final height = (bar.level / maxLevel) * 100;
                final color = _isBusyHour(bar.hour, bar.level) ? _Ds.red : _Ds.primary;

                return Container(
                  width: 24,
                  height: height.clamp(24, 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('08.00', style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
              Text(
                '12.00',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _Ds.red),
              ),
              Text('16.00', style: TextStyle(fontSize: 12, color: _Ds.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CooperativeLoaded state) {
    final aboutInfo = _infoByType(state.infoItems, 'about');
    final locationInfo = _infoByType(state.infoItems, 'location');
    final bars = _chartBars(state.crowdData);
    final status = _crowdStatus(state.currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sejarah Damos Mart'),
        const SizedBox(height: 12),
        _buildHistoryCard(aboutInfo),
        const SizedBox(height: 28),
        _buildSectionTitle('Lokasi Koperasi'),
        const SizedBox(height: 12),
        _buildLocationImage(locationInfo),
        const SizedBox(height: 12),
        _buildLocationRow(locationInfo),
        const SizedBox(height: 28),
        _buildCrowdStatusRow(status),
        const SizedBox(height: 16),
        _buildDensityChart(bars),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer(width: 180, height: 24, borderRadius: 8),
          SizedBox(height: 12),
          LoadingShimmer(width: double.infinity, height: 260, borderRadius: 12),
          SizedBox(height: 28),
          LoadingShimmer(width: 160, height: 24, borderRadius: 8),
          SizedBox(height: 12),
          LoadingShimmer(width: double.infinity, height: 180, borderRadius: 12),
          SizedBox(height: 28),
          LoadingShimmer(width: double.infinity, height: 180, borderRadius: 12),
      ],
    );
  }

  Widget _buildScrollPage(Widget child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosPageHeader(
            title: 'Informasi Koperasi',
            showBackButton: true,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<CooperativeCubit, CooperativeState>(
        builder: (context, state) {
          if (state is CooperativeLoading) {
            return _buildScrollPage(_buildShimmerLoading());
          }

          if (state is CooperativeError) {
            return _buildScrollPage(
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: ErrorState(
                  message: state.message,
                  onRetry: () => context.read<CooperativeCubit>().loadCooperativeInfo(),
                ),
              ),
            );
          }

          if (state is CooperativeLoaded) {
            return _buildScrollPage(_buildContent(state));
          }

          return _buildScrollPage(
            const SizedBox(
              height: 240,
              child: Center(child: Text('Memuat informasi koperasi...')),
            ),
          );
        },
      ),
    );
  }
}
