import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/search/search_navigation.dart';
import '../../core/utils/damos_system_ui.dart';
import 'damos_brand_header.dart';
import '../search/damos_search_bar_trigger.dart';

/// Green header with logo, tagline, profile avatar, and search bar (Beranda & Katalog).
class DamosScreenHeader extends StatelessWidget {
  const DamosScreenHeader({super.key});

  static const Color primary = DamosBrandHeaderRow.primary;
  static const Color hint = Color(0xFF6B7280);
  static const Color textPrimary = Color(0xFF1A1A1A);

  static const double profileAvatarRadius = DamosBrandHeaderRow.profileAvatarRadius;
  static const double profileBorderWidth = DamosBrandHeaderRow.profileBorderWidth;
  static const double headerIconOuterSize = DamosBrandHeaderRow.headerIconOuterSize;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Container(
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
            DamosSearchBarTrigger(
              onTap: () => SearchNavigation.open(context),
              borderRadius: 12,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
