import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/queue_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../core/utils/cart_navigation.dart';
import '../../core/utils/notification_navigation.dart';
import 'damos_history_nav_icon.dart';

class DamosBottomNav extends StatelessWidget {
  final Widget child;

  const DamosBottomNav({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/cart')) {
      return CartNavigation.selectedTabIndex(context);
    }
    if (location.startsWith('/favorites')) return 3;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/catalog')) return 1;
    if (location.startsWith('/history') || location.startsWith('/profile/history')) {
      return 2;
    }
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  Future<void> _onHistoryTap(
    BuildContext context, {
    required int readyCount,
    required List<NotificationModel> notifications,
  }) async {
    final notificationCubit = context.read<NotificationCubit>();
    var resolvedNotifications = notifications;

    if (notificationCubit.state is! NotificationLoaded) {
      await notificationCubit.loadNotifications(showLoading: false);
      final state = notificationCubit.state;
      if (state is NotificationLoaded) {
        resolvedNotifications = state.notifications;
      }
    }

    // Dot notifikasi: langsung ke detail, ditandai sudah dibaca.
    if (NotificationNavigation.hasHistoryUnread(resolvedNotifications)) {
      if (!context.mounted) return;
      final navigated = await NotificationNavigation.openLatestUnread(
        context,
        where: NotificationNavigation.isHistoryRelated,
      );
      if (navigated) return;
    }

    // Badge angka siap ambil / riwayat normal.
    if (!context.mounted) return;
    context.read<OrderCubit>().loadMyOrders();
    context.go(readyCount > 0 ? '/history?tab=ready' : '/history');
  }

  int _readyPickupCount(QueueState state, QueueCubit cubit) {
    if (state is QueueActiveLoaded) {
      return state.activeQueues
          .where((queue) => queue.status == QueueStatus.ready)
          .length;
    }
    return cubit.readyPickupCount();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: BlocBuilder<QueueCubit, QueueState>(
              builder: (context, queueState) {
                final readyCount =
                    _readyPickupCount(queueState, context.read<QueueCubit>());

                return BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, notificationState) {
                    final notifications = notificationState is NotificationLoaded
                        ? notificationState.notifications
                        : const <NotificationModel>[];
                    final historyUnreadDot =
                        NotificationNavigation.hasHistoryUnread(notifications);

                    return Row(
                      children: [
                        _NavItem(
                          label: 'Beranda',
                          isSelected: selectedIndex == 0,
                          outlineIcon: Icons.home_outlined,
                          filledIcon: Icons.home_rounded,
                          onTap: () => context.go('/home'),
                        ),
                        _NavItem(
                          label: 'Katalog',
                          isSelected: selectedIndex == 1,
                          outlineIcon: Icons.grid_view_outlined,
                          filledIcon: Icons.grid_view_rounded,
                          onTap: () => context.go('/catalog'),
                        ),
                        _NavItem(
                          label: 'Riwayat Pesanan',
                          isSelected: selectedIndex == 2,
                          iconBuilder: (color, selected) => DamosHistoryNavIcon(
                            color: color,
                            isSelected: selected,
                          ),
                          badgeCount: readyCount,
                          showDot: historyUnreadDot,
                          onTap: () => _onHistoryTap(
                            context,
                            readyCount: readyCount,
                            notifications: notifications,
                          ),
                        ),
                        _NavItem(
                          label: 'Profile',
                          isSelected: selectedIndex == 3,
                          outlineIcon: Icons.account_circle_outlined,
                          filledIcon: Icons.account_circle_rounded,
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? outlineIcon;
  final IconData? filledIcon;
  final Widget Function(Color color, bool isSelected)? iconBuilder;
  final VoidCallback onTap;
  final int badgeCount;
  final bool showDot;

  const _NavItem({
    required this.label,
    required this.isSelected,
    this.outlineIcon,
    this.filledIcon,
    this.iconBuilder,
    required this.onTap,
    this.badgeCount = 0,
    this.showDot = false,
  }) : assert(
          iconBuilder != null || (outlineIcon != null && filledIcon != null),
          'Provide iconBuilder or both outlineIcon and filledIcon',
        );

  Widget _buildIcon(Color color) {
    if (iconBuilder != null) {
      return iconBuilder!(color, isSelected);
    }
    return Icon(
      isSelected ? filledIcon! : outlineIcon!,
      size: 24,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? DamosDominanceColors.primary
        : DamosDominanceColors.navInactive;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildIcon(color),
                  if (showDot)
                    Positioned(
                      left: badgeCount > 0 ? -1 : null,
                      right: badgeCount > 0 ? null : -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: DamosDominanceColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -10,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: DamosDominanceColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
