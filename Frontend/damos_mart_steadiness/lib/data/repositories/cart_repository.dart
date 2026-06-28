import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/cart_item_model.dart';

class CartRepository {
  final DioClient _client;

  CartRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<Map<String, dynamic>> getCart() async {
    final response = await _client.get(ApiConfig.cart);
    final data = response.data['data'];
    
    final itemsList = data['items'] as List? ?? [];
    final items = itemsList
        .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return {
      'items': items,
      'totalItems': data['totalItems'] as int? ?? 0,
      'totalPrice': double.tryParse(data['totalPrice'].toString()) ?? 0.0,
    };
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    await _client.post(
      ApiConfig.cart,
      data: {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
      },
    );
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    await _client.put(
      ApiConfig.cartItem(cartItemId),
      data: {
        'quantity': quantity,
      },
    );
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _client.delete(ApiConfig.cartItem(cartItemId));
  }

  Future<void> clearCart() async {
    await _client.delete(ApiConfig.cart);
  }
}
