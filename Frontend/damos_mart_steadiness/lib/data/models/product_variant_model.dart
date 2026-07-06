import 'package:equatable/equatable.dart';

class ProductVariantModel extends Equatable {
  final String id;
  final String productId;
  final String variantName;
  final double additionalPrice;
  final int stock;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.additionalPrice,
    required this.stock,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantName': variantName,
      'additionalPrice': additionalPrice,
      'stock': stock,
    };
  }

  @override
  List<Object?> get props => [id, productId, variantName, additionalPrice, stock];
}
