import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';

class ProductStockUtils {
  ProductStockUtils._();

  static int stockFor(ProductModel product, {ProductVariantModel? variant}) {
    if (variant != null) return variant.stock;
    return product.stock;
  }

  static bool hasAvailableStock(ProductModel product) => product.stock > 0;

  static bool variantHasStock(ProductVariantModel variant) => variant.stock > 0;

  static ProductVariantModel? firstInStockVariant(ProductModel product) {
    for (final variant in product.variants) {
      if (variantHasStock(variant)) return variant;
    }
    return null;
  }
}
