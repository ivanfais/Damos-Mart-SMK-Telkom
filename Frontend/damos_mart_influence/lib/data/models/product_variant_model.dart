import 'package:equatable/equatable.dart';

class ProductVariantModel extends Equatable {
  final String id;
  final String productId;
  final String variantName;
  final double additionalPrice;
  final int stock;
  final String? imageUrl;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.additionalPrice,
    required this.stock,
    this.imageUrl,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['additionalPrice'] != null) {
      parsedPrice = double.tryParse(json['additionalPrice'].toString()) ?? 0.0;
    }

    return ProductVariantModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      variantName: json['variantName'] as String,
      additionalPrice: parsedPrice,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantName': variantName,
      'additionalPrice': additionalPrice,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  /// Variant image when set, otherwise falls back to [productImageUrl].
  static String? displayImageUrl({
    required String? productImageUrl,
    ProductVariantModel? variant,
  }) {
    final variantImage = variant?.imageUrl;
    if (variantImage != null && variantImage.isNotEmpty) {
      return variantImage;
    }
    return productImageUrl;
  }

  @override
  List<Object?> get props => [id, productId, variantName, additionalPrice, stock, imageUrl];
}
