import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/product_model.dart';

class FavoriteRepository {
  final DioClient _client;

  FavoriteRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<String>> getFavoriteIds() async {
    final response = await _client.get(ApiConfig.favoriteIds);
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final ids = data['data'] as List? ?? [];
      return ids.map((id) => id.toString()).toList();
    }
    throw ApiException(
      message: 'Gagal memuat daftar favorit',
      statusCode: response.statusCode,
    );
  }

  Future<List<ProductModel>> getFavorites({
    String? categoryId,
    String? search,
  }) async {
    final response = await _client.get(
      ApiConfig.favorites,
      queryParameters: {
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final items = data['data'] as List? ?? [];
      return items
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      message: 'Gagal memuat produk favorit',
      statusCode: response.statusCode,
    );
  }

  Future<bool> toggleFavorite(String productId) async {
    final response = await _client.post(ApiConfig.favoriteToggle(productId));
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final payload = data['data'];
      if (payload is Map) {
        return payload['isFavorite'] as bool? ?? false;
      }
    }
    throw ApiException(
      message: 'Gagal memperbarui favorit',
      statusCode: response.statusCode,
    );
  }
}
