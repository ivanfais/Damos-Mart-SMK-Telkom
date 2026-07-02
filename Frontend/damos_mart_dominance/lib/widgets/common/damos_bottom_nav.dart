import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../data/models/queue_model.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../core/utils/cart_navigation.dart';

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

  void _onItemTapped(int index, BuildContext context, {int readyCount = 0}) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/catalog');
        break;
      case 2:
        context.read<OrderCubit>().loadMyOrders();
        context.go(readyCount > 0 ? '/history?tab=ready' : '/history');
        break;
      case 3:
        context.go('/profile');
        break;
    }
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

                return Row(
                  children: [
                    _NavItem(
                      label: 'Beranda',
                      isSelected: selectedIndex == 0,
                      outlineIcon: Icons.home_outlined,
                      filledIcon: Icons.home_rounded,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _NavItem(
                      label: 'Katalog',
                      isSelected: selectedIndex == 1,
                      outlineIcon: Icons.grid_view_outlined,
                      filledIcon: Icons.grid_view_rounded,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _NavItem(
                      label: 'Riwayat Pesanan',
                      isSelected: selectedIndex == 2,
                      outlineIcon: Icons.receipt_long_outlined,
                      filledIcon: Icons.receipt_long_rounded,
                      badgeCount: readyCount,
                      onTap: () => _onItemTapped(2, context, readyCount: readyCount),
                    ),
                    _NavItem(
                      label: 'Profile',
                      isSelected: selectedIndex == 3,
                      outlineIcon: Icons.account_circle_outlined,
                      filledIcon: Icons.account_circle_rounded,
                      onTap: () => _onItemTapped(3, context),
                    ),
                  ],
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
  final IconData outlineIcon;
  final IconData filledIcon;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.outlineIcon,
    required this.filledIcon,
    required this.onTap,
    this.badgeCount = 0,
  });

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
                  Icon(
                    isSelected ? filledIcon : outlineIcon,
                    size: 24,
                    color: color,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
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
