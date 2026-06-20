import 'package:flutter/material.dart';
import 'damos_brand_header.dart';

/// Green header with logo, tagline, profile avatar, and search bar (Beranda & Katalog).
class DamosScreenHeader extends StatelessWidget {
  const DamosScreenHeader({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;

  static const Color primary = DamosBrandHeaderRow.primary;
  static const Color hint = Color(0xFF6B7280);
  static const Color textPrimary = Color(0xFF1A1A1A);

  static const double profileAvatarRadius = DamosBrandHeaderRow.profileAvatarRadius;
  static const double profileBorderWidth = DamosBrandHeaderRow.profileBorderWidth;
  static const double headerIconOuterSize = DamosBrandHeaderRow.headerIconOuterSize;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DamosBrandHeaderRow(showProfileAvatar: true),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              children: [
                const Icon(Icons.search, color: hint, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchSubmitted,
                    style: const TextStyle(fontSize: 14, color: textPrimary),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Cari produk, kategori, atau merek...',
                      hintStyle: TextStyle(color: hint, fontSize: 14),
                    ),
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
