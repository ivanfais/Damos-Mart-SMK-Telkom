import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/product_model.dart';

class FavoriteRepository {
  final DioClient _client;

  FavoriteRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<String>> getFavoriteIds() async {
    final response = await _client.get(ApiConfig.favoriteIds);
    final dataList = response.data['data'] as List? ?? [];
    return dataList.map((id) => id as String).toList();
  }

  Future<List<ProductModel>> getFavorites() async {
    final response = await _client.get(ApiConfig.favorites);
    final dataList = response.data['data'] as List? ?? [];
    return dataList.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleFavorite(String productId) async {
    final response = await _client.post(ApiConfig.favoriteToggle(productId));
    final data = response.data['data'] as Map<String, dynamic>;
    return data['isFavorite'] as bool;
  }

  Future<void> removeFavorite(String productId) async {
    await _client.delete(ApiConfig.favoriteRemove(productId));
  }
}
