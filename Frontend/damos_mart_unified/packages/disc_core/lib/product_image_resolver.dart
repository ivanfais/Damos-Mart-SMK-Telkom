import 'disc_variant.dart';

typedef VariantImageSource = ({String variantName, String? imageUrl});

/// Resolves which product image URL to show in the student app.
///
/// Priority:
/// 1. Selected variant image (e.g. size S/M/L with its own photo)
/// 2. Variant whose name matches the active DISC theme (Influence, Dominance, …)
/// 3. Product main image
class ProductImageResolver {
  const ProductImageResolver._();

  static bool variantNameMatchesDisc(String variantName, DiscVariant disc) {
    final normalized = variantName.trim().toLowerCase();
    return normalized == disc.name.toLowerCase() ||
        normalized == disc.label.toLowerCase() ||
        normalized == disc.apiValue.toLowerCase();
  }

  static String? resolve({
    required String? productImageUrl,
    required List<VariantImageSource> variants,
    VariantImageSource? selectedVariant,
    DiscVariant? discVariant,
  }) {
    final selectedImage = selectedVariant?.imageUrl;
    if (selectedImage != null && selectedImage.isNotEmpty) {
      return selectedImage;
    }

    if (discVariant != null) {
      for (final variant in variants) {
        if (variantNameMatchesDisc(variant.variantName, discVariant) &&
            variant.imageUrl != null &&
            variant.imageUrl!.isNotEmpty) {
          return variant.imageUrl;
        }
      }
    }

    return productImageUrl;
  }
}
