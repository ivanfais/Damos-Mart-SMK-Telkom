import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../core/utils/cart_navigation.dart';
import '../../core/utils/damos_system_ui.dart';
import '../../theme/damos_dominance_colors.dart';

/// Green header for Favorite Saya — single row per design.
class DamosFavoritesHeader extends StatelessWidget {
  const DamosFavoritesHeader({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onBack,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onBack;

  static const double _searchHeight = 40;

  Widget _buildCartButton(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state is CartLoaded ? state.totalItems : 0,
      builder: (context, count) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: DamosDominanceColors.cartButtonFill,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => CartNavigation.open(context),
                  child: const SizedBox(
                    width: _searchHeight,
                    height: _searchHeight,
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
                  top: -4,
                  right: -4,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.none,
        color: DamosDominanceColors.primary,
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                Icons.arrow_back,
                color: DamosDominanceColors.textOnPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Favorite Saya',
              style: TextStyle(
                color: DamosDominanceColors.textOnPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: _searchHeight,
                decoration: BoxDecoration(
                  color: DamosDominanceColors.cartButtonFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: DamosDominanceColors.textHint,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: onSearchSubmitted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DamosDominanceColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: 'Cari produk...',
                          hintStyle: TextStyle(
                            color: DamosDominanceColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildCartButton(context),
          ],
        ),
      ),
    );
  }
}
