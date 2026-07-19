import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_model.dart';
import '../models/complaint_subject_option.dart';
import '../models/order_model.dart';
import 'order_repository.dart';

class ComplaintRepository {
  final DioClient _client;
  final OrderRepository _orderRepository;

  ComplaintRepository({
    DioClient? client,
    OrderRepository? orderRepository,
  })  : _client = client ?? DioClient.instance,
        _orderRepository = orderRepository ?? OrderRepository();

  Future<ComplaintModel> createComplaint({
    required ComplaintSubjectOption subject,
    required String description,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    final orderId = await _resolveCompletedOrderId();

    final formData = FormData.fromMap({
      'orderId': orderId,
      'reason': subject.toBackendReason(),
      'description': description,
    });

    if (photoBytes != null && photoBytes.isNotEmpty) {
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            photoBytes,
            filename: photoFileName?.trim().isNotEmpty == true
                ? photoFileName!.trim()
                : 'complaint_photo.jpg',
          ),
        ),
      );
    }

    final response = await _client.post(
      ApiConfig.complaints,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final payload = data['data'];
      if (payload is Map) {
        return ComplaintModel.fromJson(Map<String, dynamic>.from(payload));
      }
    }

    throw ApiException(
      message: 'Gagal mengirim komplain',
      statusCode: response.statusCode,
    );
  }

  Future<String> _resolveCompletedOrderId() async {
    final orders = await _orderRepository.getMyOrders();
    for (final order in orders) {
      if (order.status == OrderStatus.completed && order.id.isNotEmpty) {
        return order.id;
      }
    }

    throw ApiException(
      message:
          'Belum ada pesanan selesai yang dapat dikaitkan dengan komplain. Selesaikan minimal satu pesanan terlebih dahulu.',
    );
  }

  Future<List<ComplaintModel>> getMyComplaints() async {
    final response = await _client.get(ApiConfig.myComplaints);
    final data = response.data;

    if (data is Map && data['success'] == true) {
      final payload = data['data'];
      if (payload is List) {
        return payload
            .whereType<Map>()
            .map((item) => ComplaintModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    throw ApiException(
      message: 'Gagal memuat riwayat komplain',
      statusCode: response.statusCode,
    );
  }
}
