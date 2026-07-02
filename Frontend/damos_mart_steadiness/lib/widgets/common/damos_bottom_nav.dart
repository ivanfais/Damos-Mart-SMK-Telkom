import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class DamosBottomNav extends StatelessWidget {
  final Widget child;

  const DamosBottomNav({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/catalog')) return 1;
    if (location.startsWith('/queue')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/catalog');
        break;
      case 2:
        final queueCubit = context.read<QueueCubit>();
        final authState = context.read<AuthBloc>().state;
        final userId = authState is Authenticated ? authState.user.id : null;
        context.go('/queue');
        queueCubit.refreshQueueList(userId: userId);
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    const items = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Katalog'),
      (icon: Icons.hourglass_empty_outlined, activeIcon: Icons.hourglass_empty, label: 'Antrean'),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index, context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                )
                              : null,
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
