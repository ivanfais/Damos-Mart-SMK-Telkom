import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../core/utils/notification_display_utils.dart';
import '../../data/models/notification_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/steadiness_app_header.dart';
import '../../theme/app_text_styles.dart';

/// Teks notifikasi memakai Inter (via [AppTextStyles.fontFamily]).
class _NotificationTextTheme extends StatelessWidget {
  const _NotificationTextTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );

    return DefaultTextStyle(
      style: base,
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: AppTextStyles.fontFamily,
                bodyColor: NotificationDisplayColors.textPrimary,
                displayColor: NotificationDisplayColors.textPrimary,
              ),
        ),
        child: child,
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  Timer? _autoRefreshTimer;
  int _listVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().loadNotifications();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
      context.read<NotificationCubit>().loadNotifications();
    }
  }

  void _bumpListVersion() {
    if (!mounted) return;
    setState(() => _listVersion++);
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationCubit>().loadNotifications();
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
          context.go('/profile');
        }
    }
  }

  Future<void> _markAllAsRead() async {
    final state = context.read<NotificationCubit>().state;
    if (state is! NotificationLoaded || state.unreadCount == 0) return;
    await context.read<NotificationCubit>().markAllAsRead();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    final cubit = context.read<NotificationCubit>();
    if (!notification.isRead) {
      await cubit.markAsRead(notification.id);
    }
    if (!mounted) return;
    _navigateForNotification(notification);
  }

  void _navigateForNotification(NotificationModel notification) {
    final ref = notification.referenceId;

    switch (notification.type) {
      case NotificationType.queueReady:
        if (ref != null && ref.isNotEmpty) {
          context.push('/queue/$ref');
        } else {
          context.go('/queue');
        }
        return;
      case NotificationType.orderStatus:
        if (ref != null && ref.isNotEmpty) {
          context.push('/orders/history/$ref');
        } else {
          context.go('/profile?view=history');
        }
        return;
      case NotificationType.complaint:
        if (ref != null && ref.isNotEmpty) {
          context.push('/profile/chat/complaints/$ref/track');
        } else {
          context.push('/profile/chat');
        }
        return;
      case NotificationType.chat:
        context.push('/profile/chat');
        return;
      case NotificationType.promo:
        context.go('/catalog');
        return;
    }
  }

  List<Widget> _buildNotificationList(
    Map<NotificationTimeGroup, List<NotificationModel>> grouped,
  ) {
    final children = <Widget>[];
    var isFirstSection = true;

    for (final group in NotificationDisplayUtils.visibleGroups) {
      final notifications = grouped[group];
      if (notifications == null || notifications.isEmpty) continue;

      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: 10, top: isFirstSection ? 0 : 8),
          child: _SectionHeader(
            title: NotificationDisplayUtils.groupTitle(group)!,
          ),
        ),
      );
      isFirstSection = false;

      for (final notification in notifications) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationCard(
              key: ValueKey('${notification.id}-$_listVersion'),
              notification: notification,
              onTap: () => _onNotificationTap(notification),
            ),
          ),
        );
      }
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return _NotificationTextTheme(
      child: Scaffold(
        backgroundColor: NotificationDisplayColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SteadinessAppHeader(
              showNotificationButton: false,
              onBack: _onBack,
            ),
            Expanded(
              child: BlocConsumer<NotificationCubit, NotificationState>(
                listenWhen: (previous, current) => current is NotificationLoaded,
                listener: (context, state) {
                  _bumpListVersion();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _bumpListVersion();
                  });
                },
                builder: (context, state) {
                  final showReadAll = state is NotificationLoaded && state.unreadCount > 0;

                  Widget content;
                  if (state is NotificationError) {
                    content = RefreshIndicator(
                      color: NotificationDisplayColors.primary,
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.35,
                            child: ErrorState(
                              message: state.message,
                              onRetry: () =>
                                  context.read<NotificationCubit>().loadNotifications(),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is NotificationLoading) {
                    content = const Center(
                      child: CircularProgressIndicator(
                        color: NotificationDisplayColors.primary,
                      ),
                    );
                  } else if (state is! NotificationLoaded) {
                    content = const Center(
                      child: CircularProgressIndicator(
                        color: NotificationDisplayColors.primary,
                      ),
                    );
                  } else if (state.notifications.isEmpty) {
                    content = _NotificationsEmptyState(onRefresh: _onRefresh);
                  } else {
                    final grouped =
                        NotificationDisplayUtils.groupNotifications(state.notifications);

                    if (grouped.values.every((items) => items.isEmpty)) {
                      content = _NotificationsEmptyState(onRefresh: _onRefresh);
                    } else {
                      final listChildren = _buildNotificationList(grouped);

                      content = RefreshIndicator(
                        color: NotificationDisplayColors.primary,
                        onRefresh: _onRefresh,
                        child: ListView(
                          key: ValueKey(
                            'list-$_listVersion-${state.updatedAt.millisecondsSinceEpoch}',
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, showReadAll ? 4 : 16, 16, 24),
                          addRepaintBoundaries: false,
                          children: listChildren,
                        ),
                      );
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showReadAll)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _markAllAsRead,
                              icon: const Icon(Icons.done_all_outlined, size: 18),
                              label: const Text(
                                'Baca Semua',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: NotificationDisplayColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                        ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NotificationDisplayColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.notifications_none_outlined,
                  size: 56,
                  color: NotificationDisplayColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada notifikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NotificationDisplayColors.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk memuat ulang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: NotificationDisplayColors.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: NotificationDisplayColors.textPrimary,
        fontFamily: AppTextStyles.fontFamily,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Color(0xFF1B8C2E),
    fontFamily: AppTextStyles.fontFamily,
    height: 1.3,
  );

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B7280),
    fontFamily: AppTextStyles.fontFamily,
    height: 1.45,
  );

  static const TextStyle _timeStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF6B7280),
    fontFamily: AppTextStyles.fontFamily,
  );

  static const TextStyle _tagStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1B8C2E),
    fontFamily: AppTextStyles.fontFamily,
  );

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final icon = NotificationDisplayUtils.iconFor(notification);
    final category = NotificationDisplayUtils.categoryLabel(notification.type);
    final timeLabel = NotificationDisplayUtils.timeLabel(notification.createdAt);
    final title = notification.title.trim().isNotEmpty
        ? notification.title.trim()
        : 'Notifikasi';
    final body = notification.body.trim().isNotEmpty
        ? notification.body.trim()
        : 'Tidak ada detail notifikasi.';

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread
              ? NotificationDisplayColors.primary
              : NotificationDisplayColors.border,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(isUnread ? 11 : 14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? const Border(
                    left: BorderSide(
                      color: NotificationDisplayColors.primary,
                      width: 4,
                    ),
                  )
                : null,
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
                      color: NotificationDisplayColors.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: NotificationDisplayColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _titleStyle),
                  ),
                  const SizedBox(width: 8),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6, top: 4),
                      decoration: const BoxDecoration(
                        color: NotificationDisplayColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(timeLabel, style: _timeStyle),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(body, maxLines: 4, overflow: TextOverflow.ellipsis, style: _bodyStyle),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NotificationDisplayColors.tagBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category, style: _tagStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
