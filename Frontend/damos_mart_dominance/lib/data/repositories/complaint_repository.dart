import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_create_result.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final DioClient _client;

  ComplaintRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ComplaintCreateResult> createComplaint({
    required String subject,
    required String description,
    required String category,
    String? orderId,
  }) async {
    final response = await _client.post(
      ApiConfig.complaints,
      data: {
        'subject': subject,
        'description': description,
        'category': category,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      },
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final payload = data['data'];
      if (payload is Map) {
        final id = payload['id']?.toString();
        if (id != null && id.isNotEmpty) {
          final createdAtRaw = payload['createdAt']?.toString();
          final createdAt = createdAtRaw != null
              ? DateTime.parse(createdAtRaw).toLocal()
              : DateTime.now();
          return ComplaintCreateResult(
            id: id,
            message: data['message'] as String? ?? 'Komplain berhasil dikirim',
            createdAt: createdAt,
          );
        }
      }

      throw ApiException(
        message: 'Gagal mengirim komplain',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      message: 'Gagal mengirim komplain',
      statusCode: response.statusCode,
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
      return [];
    }

    throw ApiException(
      message: 'Gagal memuat daftar komplain',
      statusCode: response.statusCode,
    );
  }

  Future<List<ComplaintModel>> getComplaintsForOrder(String orderId) async {
    final complaints = await getMyComplaints();
    return complaints.where((c) => c.orderId == orderId).toList();
  }

  Future<ComplaintModel?> findComplaintById(String id) async {
    final complaints = await getMyComplaints();
    for (final complaint in complaints) {
      if (complaint.id == id) return complaint;
    }
    return null;
  }
}
