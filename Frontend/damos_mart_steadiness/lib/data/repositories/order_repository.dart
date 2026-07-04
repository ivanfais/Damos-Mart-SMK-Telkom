import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DioClient _client;

  OrderRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<OrderModel> createOrder({
    required List<String> cartItemIds,
    required String paymentMethod,
    String? notes,
  }) async {
    final response = await _client.post(
      ApiConfig.orders,
      data: {
        'cartItemIds': cartItemIds,
        'paymentMethod': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _client.get(
      ApiConfig.orders,
      queryParameters: const {'limit': 50},
    );
    final body = response.data;

    if (body is Map && body['success'] == true) {
      final dataList = body['data'];
      if (dataList is List) {
        final orders = <OrderModel>[];
        for (final item in dataList) {
          if (item is! Map) continue;
          try {
            orders.add(OrderModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Lewati item rusak agar daftar lain tetap tampil.
          }
        }
        return orders;
      }
    }

    return [];
  }

  Future<OrderModel> getOrderDetails(String id) async {
    final response = await _client.get(ApiConfig.orderDetail(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> payOrder(String id, {required String paymentMethod}) async {
    final response = await _client.post(
      ApiConfig.payOrder(id),
      data: {
        'paymentMethod': paymentMethod,
      },
    );

    // Backend returns { order, queue }. Merge the queue into the order JSON so
    // the resulting OrderModel carries the generated queue number.
    final data = response.data['data'] as Map<String, dynamic>;
    final orderJson = Map<String, dynamic>.from(data['order'] as Map<String, dynamic>);
    if (data['queue'] != null) {
      orderJson['queue'] = data['queue'];
    }
    return OrderModel.fromJson(orderJson);
  }

  Future<OrderModel> cancelOrder(String id) async {
    final response = await _client.post(ApiConfig.cancelOrder(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}
