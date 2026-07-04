import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/queue/queue_cubit.dart';
import '../../theme/app_dimensions.dart';

class _NavColors {
  static const Color active = Color(0xFF1B8C2E);
  static const Color inactive = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
}

class DamosBottomNav extends StatelessWidget {
  final Widget child;

  const DamosBottomNav({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/catalog')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/queue')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/notifications')) return 4;
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
        context.go('/cart');
        break;
      case 3:
        final queueCubit = context.read<QueueCubit>();
        final authState = context.read<AuthBloc>().state;
        final userId = authState is Authenticated ? authState.user.id : null;
        context.go('/queue');
        queueCubit.refreshQueueList(userId: userId);
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    const items = [
      (icon: Icons.home_outlined, label: 'Home'),
      (icon: Icons.grid_view_outlined, label: 'Katalog'),
      (icon: Icons.shopping_cart_outlined, label: 'Keranjang'),
      (icon: Icons.hourglass_empty_outlined, label: 'Antrean'),
      (icon: Icons.person_outline, label: 'Profil'),
    ];

    return Scaffold(
      body: SizedBox.expand(child: child),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _NavColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                final color = isSelected ? _NavColors.active : _NavColors.inactive;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index, context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: color, size: 26),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                            fontFamily: 'Arial',
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
