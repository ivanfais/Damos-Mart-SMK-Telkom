import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final bool isPreorder;
  final String? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final bool inStock;
  final int availableStock;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.isPreorder,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.inStock,
    required this.availableStock,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String?,
      isPreorder: json['isPreorder'] as bool? ?? false,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      unitPrice: double.tryParse(json['unitPrice'].toString()) ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      inStock: json['inStock'] as bool? ?? true,
      availableStock: json['availableStock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'isPreorder': isPreorder,
      'variantId': variantId,
      'variantName': variantName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'inStock': inStock,
      'availableStock': availableStock,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        imageUrl,
        isPreorder,
        variantId,
        variantName,
        unitPrice,
        quantity,
        subtotal,
        inStock,
        availableStock,
      ];
}
