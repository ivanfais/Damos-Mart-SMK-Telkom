import 'package:flutter/material.dart';
import '../../core/utils/damos_horizontal_scroll_behavior.dart';
import 'damos_home_product_card.dart';

/// Horizontal product carousel with mouse/touch drag support on Flutter web.
class DamosHomeProductCarousel extends StatelessWidget {
  static const double itemSpacing = 16;

  final List<Widget> children;

  const DamosHomeProductCarousel({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox(height: DamosHomeProductCard.cardHeight);
    }

    return SizedBox(
      height: DamosHomeProductCard.cardHeight,
      child: ScrollConfiguration(
        behavior: const DamosHorizontalScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: itemSpacing),
          itemBuilder: (_, index) => children[index],
        ),
      ),
    );
  }
}
