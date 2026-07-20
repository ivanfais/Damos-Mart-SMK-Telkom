import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../core/utils/notification_display_utils.dart';
import '../../core/utils/notification_navigation.dart';
import '../../data/models/notification_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/damos_page_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().loadNotifications();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      context.read<NotificationCubit>().refreshSilently();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationCubit>().loadNotifications(showLoading: false);
    }
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationCubit>().loadNotifications(showLoading: false);
  }

  void _onBack() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    switch (from) {
      case 'profile':
        context.go('/profile');
        return;
      case 'home':
        context.go('/home');
        return;
      default:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
    }
  }

  Future<void> _markAllAsRead() async {
    final state = context.read<NotificationCubit>().state;
    if (state is! NotificationLoaded || state.unreadCount == 0) return;
    await context.read<NotificationCubit>().markAllAsRead();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await context.read<NotificationCubit>().markAsRead(notification.id);
    }
    if (!mounted) return;
    _navigateForNotification(notification);
  }

  void _navigateForNotification(NotificationModel notification) {
    NotificationNavigation.navigate(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: Column(
        children: [
          DamosPageHeader(
            title: 'Notifikasi',
            showBackButton: true,
            onBack: _onBack,
          ),
          Expanded(
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final showReadAll =
                    state is NotificationLoaded && state.unreadCount > 0;

                if (state is NotificationError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<NotificationCubit>().loadNotifications(),
                  );
                }

                if (state is NotificationLoading) {
                  return const DamosListCardShimmer();
                }

                if (state is! NotificationLoaded) {
                  return const SizedBox.shrink();
                }

                if (state.notifications.isEmpty) {
                  return RefreshIndicator(
                    color: DamosDominanceColors.primary,
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  size: 56,
                                  color: DamosDominanceColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada notifikasi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: DamosDominanceColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tarik ke bawah untuk memuat ulang',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: DamosDominanceColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final grouped =
                    NotificationDisplayUtils.groupNotifications(state.notifications);

                return Column(
                  children: [
                    if (showReadAll)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _markAllAsRead,
                            icon: const Icon(Icons.done_all_outlined, size: 18),
                            label: const Text('Baca Semua'),
                            style: TextButton.styleFrom(
                              foregroundColor: DamosDominanceColors.primary,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        color: DamosDominanceColors.primary,
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            for (final group
                                in NotificationDisplayUtils.visibleGroups) ...[
                              if (grouped[group]?.isNotEmpty ?? false) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    NotificationDisplayUtils.groupTitle(group)!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: DamosDominanceColors.textPrimary,
                                    ),
                                  ),
                                ),
                                for (final notification in grouped[group]!)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _NotificationCard(
                                      notification: notification,
                                      onTap: () =>
                                          _onNotificationTap(notification),
                                    ),
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final icon = NotificationDisplayUtils.iconFor(notification);
    final category =
        NotificationDisplayUtils.categoryLabel(notification.type);
    final timeLabel =
        NotificationDisplayUtils.timeLabel(notification.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(isUnread ? 11 : 14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUnread
                  ? DamosDominanceColors.primary
                  : DamosDominanceColors.fieldBorder,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NotificationDisplayUtils.iconBackgroundFor(
                        notification,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: DamosDominanceColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isUnread
                            ? DamosDominanceColors.primary
                            : DamosDominanceColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6, top: 4),
                      decoration: const BoxDecoration(
                        color: DamosDominanceColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DamosDominanceColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(
                  notification.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DamosDominanceColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DamosDominanceColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DamosDominanceColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
