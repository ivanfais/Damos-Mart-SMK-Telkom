import 'package:equatable/equatable.dart';
import 'product_variant_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isPreorder;
  final String? preorderEstimation;
  final bool isActive;
  final double averageRating;
  final int totalReviews;
  final String categoryName;
  final List<ProductVariantModel> variants;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isPreorder,
    this.preorderEstimation,
    required this.isActive,
    required this.averageRating,
    required this.totalReviews,
    required this.categoryName,
    required this.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Price parsing
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // Rating parsing
    double parsedRating = 0.0;
    if (json['averageRating'] != null) {
      parsedRating = double.tryParse(json['averageRating'].toString()) ?? 0.0;
    }

    // Category Name parsing (which can be from category relation object, or string categoryName)
    String parsedCategoryName = '';
    if (json['category'] != null && json['category'] is Map) {
      parsedCategoryName = json['category']['name'] as String? ?? '';
    } else if (json['categoryName'] != null) {
      parsedCategoryName = json['categoryName'] as String;
    }

    // Variants list mapping
    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: parsedPrice,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      isPreorder: json['isPreorder'] as bool? ?? false,
      preorderEstimation: json['preorderEstimation'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      averageRating: parsedRating,
      totalReviews: json['totalReviews'] as int? ?? 0,
      categoryName: parsedCategoryName,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isPreorder': isPreorder,
      'preorderEstimation': preorderEstimation,
      'isActive': isActive,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'categoryName': categoryName,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        description,
        price,
        stock,
        imageUrl,
        isPreorder,
        preorderEstimation,
        isActive,
        averageRating,
        totalReviews,
        categoryName,
        variants,
      ];
}
