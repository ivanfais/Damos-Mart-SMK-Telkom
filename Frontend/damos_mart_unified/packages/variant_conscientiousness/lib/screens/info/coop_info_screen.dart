import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/cooperative/cooperative_cubit.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../config/api_config.dart';
import '../../data/models/cooperative_info_model.dart';
import '../../data/models/notification_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color bgLight = Color(0xFFF9F9F9);
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

class _CoopInfoScreenState extends State<CoopInfoScreen> with SingleTickerProviderStateMixin {
  static const _chartHours = [8, 9, 10, 11, 12, 13, 14, 15, 16];
  static const _dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<NotificationCubit>().loadNotifications();
    context.read<CooperativeCubit>().loadCooperativeInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Notifikasi tab ─────────────────────────────────────────────────────

  String _dateSectionLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime).toUpperCase();
  }

  List<MapEntry<String, List<NotificationModel>>> _groupByDate(List<NotificationModel> notifications) {
    final grouped = <String, List<NotificationModel>>{};
    for (final n in notifications) {
      final label = _dateSectionLabel(n.createdAt);
      grouped.putIfAbsent(label, () => []).add(n);
    }
    return grouped.entries.toList();
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationCubit>().markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: notification.isRead ? _Ds.bgGrey : _Ds.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Ds.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(notification.createdAt),
                        style: const TextStyle(fontSize: 12, color: _Ds.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(fontSize: 13, color: _Ds.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 140, height: 1, color: _Ds.borderLight),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Notifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _Ds.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: _buildNotificationEmptyState(),
      );
    }

    final sections = _groupByDate(notifications);

    return RefreshIndicator(
      color: _Ds.primary,
      onRefresh: () async => context.read<NotificationCubit>().loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: sectionIndex == sections.length - 1 ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.key,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Ds.textSecondary),
                ),
                const SizedBox(height: 12),
                ...section.value.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationCard(n),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Ds.borderLight),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(width: 160, height: 16, borderRadius: 4),
            SizedBox(height: 8),
            LoadingShimmer(width: double.infinity, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTab() {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return _buildNotificationShimmer();
        }
        if (state is NotificationError) {
          return ErrorState(
            message: state.message,
            onRetry: () => context.read<NotificationCubit>().loadNotifications(),
          );
        }
        if (state is NotificationLoaded) {
          return _buildNotificationList(state.notifications);
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── Informasi tab ──────────────────────────────────────────────────────

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
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _Ds.primary),
                  ),
                ),
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

  Widget _buildOperatingHoursCard(List<OperatingHourModel> hours) {
    final sorted = List<OperatingHourModel>.from(hours)..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final today = DateTime.now().weekday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Ds.borderLight),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final hour = entry.value;
          final isToday = hour.dayOfWeek == today;
          final dayName = (hour.dayOfWeek >= 1 && hour.dayOfWeek <= 7) ? _dayNames[hour.dayOfWeek] : '-';
          final timeLabel = hour.isClosed ? 'Tutup' : '${hour.openTime ?? '-'} - ${hour.closeTime ?? '-'}';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: index == sorted.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: _Ds.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? _Ds.primary : _Ds.textPrimary,
                  ),
                ),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hour.isClosed ? _Ds.red : _Ds.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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

  Widget _buildInformationContent(CooperativeLoaded state) {
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
        _buildSectionTitle('Jam Buka Koperasi'),
        const SizedBox(height: 12),
        _buildOperatingHoursCard(state.operatingHours),
        const SizedBox(height: 28),
        _buildCrowdStatusRow(status),
        const SizedBox(height: 16),
        _buildDensityChart(bars),
      ],
    );
  }

  Widget _buildInformationShimmer() {
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

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<CooperativeCubit, CooperativeState>(
        builder: (context, state) {
          if (state is CooperativeLoading) {
            return _buildInformationShimmer();
          }

          if (state is CooperativeError) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: ErrorState(
                message: state.message,
                onRetry: () => context.read<CooperativeCubit>().loadCooperativeInfo(),
              ),
            );
          }

          if (state is CooperativeLoaded) {
            return _buildInformationContent(state);
          }

          return const SizedBox(
            height: 240,
            child: Center(child: Text('Memuat informasi koperasi...')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgLight,
      body: Column(
        children: [
          const DamosPageHeader(
            title: 'Informasi & Notifikasi',
            showBackButton: true,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _Ds.primary,
              unselectedLabelColor: _Ds.textSecondary,
              indicatorColor: _Ds.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Notifikasi'),
                Tab(text: 'Informasi'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationTab(),
                _buildInformationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
