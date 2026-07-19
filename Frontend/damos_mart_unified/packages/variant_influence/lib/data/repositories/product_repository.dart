import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductRepository {
  final DioClient _client;

  ProductRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    bool? inStock,
    bool? isPreorder,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      ApiConfig.products,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (inStock != null) 'inStock': inStock.toString(),
        if (isPreorder != null) 'isPreorder': isPreorder.toString(),
        'sort': sort,
        'page': page,
        'limit': limit,
      },
    );

    final dataList = response.data['data'] as List? ?? [];
    final products = dataList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();

    PaginationInfo? pagination;
    if (response.data['pagination'] != null) {
      pagination = PaginationInfo.fromJson(response.data['pagination'] as Map<String, dynamic>);
    }

    return {
      'products': products,
      'pagination': pagination,
    };
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    final response = await _client.get(
      ApiConfig.featuredProducts,
      queryParameters: {'limit': limit},
    );

    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductDetail(String id) async {
    final response = await _client.get(ApiConfig.productDetail(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ProductModel.fromJson(data);
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get(ApiConfig.categories);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getProductReviews(String productId, {int page = 1, int limit = 10}) async {
    final response = await _client.get(
      ApiConfig.productReviews(productId),
      queryParameters: {'page': page, 'limit': limit},
    );

    final dataList = response.data['data'] as List? ?? [];
    PaginationInfo? pagination;
    if (response.data['pagination'] != null) {
      pagination = PaginationInfo.fromJson(response.data['pagination'] as Map<String, dynamic>);
    }

    return {
      'reviews': dataList,
      'pagination': pagination,
    };
  }
}
