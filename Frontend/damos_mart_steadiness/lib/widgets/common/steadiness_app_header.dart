import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_constants.dart';

class SteadinessHeaderColors {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color telkomRed = Color(0xFFE52521);
  static const Color telkomYellow = Color(0xFFFFCC00);
}

/// Header beranda/katalog: back, logo Damos Mart, notifikasi, garis tricolor.
class SteadinessAppHeader extends StatelessWidget {
  const SteadinessAppHeader({
    super.key,
    this.onBack,
    this.bottom,
  });

  final VoidCallback? onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    const headerIconSize = 48.0;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPadding + 6, 8, 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: headerIconSize,
                    height: headerIconSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onBack ??
                          () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: SteadinessHeaderColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SteadinessHeaderLogo(),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: headerIconSize,
                    height: headerIconSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF424242),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SteadinessHeaderTricolorStripe(),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class SteadinessHeaderLogo extends StatelessWidget {
  const SteadinessHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.imageLogo,
      width: 118,
      height: 62,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.storefront_outlined,
        color: SteadinessHeaderColors.primary,
        size: 32,
      ),
    );
  }
}

class SteadinessHeaderTricolorStripe extends StatelessWidget {
  const SteadinessHeaderTricolorStripe({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ColoredBox(
          color: SteadinessHeaderColors.telkomRed,
          child: SizedBox(height: 3, width: double.infinity),
        ),
        ColoredBox(
          color: SteadinessHeaderColors.telkomYellow,
          child: SizedBox(height: 3, width: double.infinity),
        ),
        ColoredBox(
          color: SteadinessHeaderColors.primary,
          child: SizedBox(height: 3, width: double.infinity),
        ),
      ],
    );
  }
}

/// Header halaman profil: back hitam, judul tengah, notifikasi hijau.
class SteadinessTitleHeader extends StatelessWidget {
  const SteadinessTitleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onNotificationTap,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    const headerIconSize = 48.0;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPadding + 6, 8, 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: headerIconSize,
                    height: headerIconSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onBack ??
                          () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1A1A1A),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: headerIconSize,
                    height: headerIconSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onNotificationTap ?? () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: SteadinessHeaderColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }
}

class SteadinessSearchBar extends StatelessWidget {
  const SteadinessSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.hintText = 'Cari seragam atau alat tulis...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SteadinessHeaderColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
