import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/profile')) return 4;
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
        context.go('/queue');
        break;
      case 3:
        context.go('/cart');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: AppDimensions.bottomNavHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusLarge),
            topRight: Radius.circular(AppDimensions.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusLarge),
            topRight: Radius.circular(AppDimensions.radiusLarge),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view, color: AppColors.primary),
                label: 'Katalog',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hourglass_top_outlined),
                activeIcon: Icon(Icons.hourglass_top, color: AppColors.primary),
                label: 'Antrean',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
                label: 'Keranjang',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
