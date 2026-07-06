import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final DioClient _client;

  ComplaintRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ComplaintModel> createComplaint({
    required String subject,
    required String description,
    required String category,
  }) async {
    final response = await _client.post(
      ApiConfig.complaints,
      data: {
        'subject': subject,
        'description': description,
        'category': category,
      },
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return ComplaintModel.fromJson(payload);
      }
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
    }

    throw ApiException(
      message: 'Gagal memuat riwayat komplain',
      statusCode: response.statusCode,
    );
  }
}
