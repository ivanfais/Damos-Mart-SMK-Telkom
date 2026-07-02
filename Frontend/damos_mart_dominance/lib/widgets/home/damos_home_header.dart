import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../core/utils/damos_system_ui.dart';
import '../../core/utils/cart_navigation.dart';
import '../../theme/damos_dominance_colors.dart';

/// Green header for Beranda — greeting, search bar, and cart shortcut.
class DamosHomeHeader extends StatelessWidget {
  const DamosHomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;

  String _greeting(AuthState state) {
    if (state is Authenticated) {
      final name = state.user.fullName.trim();
      if (name.isNotEmpty) {
        final firstName = name.split(' ').first;
        return 'Halo $firstName!';
      }
    }
    return 'Halo Pelajar!';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Container(
        width: double.infinity,
        color: DamosDominanceColors.primary,
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(state),
                      style: const TextStyle(
                        color: DamosDominanceColors.textOnPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'DAMOS MART',
                      style: TextStyle(
                        color: DamosDominanceColors.textOnPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: DamosDominanceColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: onSearchSubmitted,
                            style: const TextStyle(
                              fontSize: 14,
                              color: DamosDominanceColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'Cari produk...',
                              hintStyle: TextStyle(
                                color: DamosDominanceColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    final count = state is CartLoaded ? state.totalItems : 0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: DamosDominanceColors.cartButtonFill,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => CartNavigation.open(context),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: DamosDominanceColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: DamosDominanceColors.error,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
