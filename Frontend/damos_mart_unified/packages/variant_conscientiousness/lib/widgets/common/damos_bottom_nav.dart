import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

// Tab order (Figma): Keranjang | Antrean | Beranda | Katalog | Profil
class DamosBottomNav extends StatelessWidget {
  final Widget child;
  const DamosBottomNav({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/cart'))    return 0;
    if (loc.startsWith('/queue'))   return 1;
    if (loc.startsWith('/home'))    return 2;
    if (loc.startsWith('/seragam')) return -1; // tidak ada yang di-highlight
    if (loc.startsWith('/catalog')) return 3;
    if (loc.startsWith('/profile')) return 4;
    return 2;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/cart');    break;
      case 1: context.go('/queue');   break;
      case 2: context.go('/home');    break;
      case 3: context.go('/catalog'); break;
      case 4: context.go('/profile'); break;
    }
  }

static const _items = [
    _NavItem(icon: Icons.shopping_cart_outlined,  activeIcon: Icons.shopping_cart,  label: 'Keranjang'),
    _NavItem(icon: Icons.hourglass_top_outlined,  activeIcon: Icons.hourglass_top,  label: 'Antrean'),
    _NavItem(icon: Icons.home_outlined,           activeIcon: Icons.home,           label: 'Beranda'),
    _NavItem(icon: Icons.grid_view_outlined,      activeIcon: Icons.grid_view,      label: 'Katalog'),
    _NavItem(icon: Icons.person_outline,          activeIcon: Icons.person,         label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _getSelectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final isActive = i == selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(i, context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFDCF5E0) : Colors.white,
                        border: isActive
                            ? const Border(
                                top: BorderSide(color: AppColors.primary, width: 2),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? _items[i].activeIcon : _items[i].icon,
                            size: 22,
                            color: isActive ? AppColors.primary : const Color(0xFF888888),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].label,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive ? AppColors.primary : const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
