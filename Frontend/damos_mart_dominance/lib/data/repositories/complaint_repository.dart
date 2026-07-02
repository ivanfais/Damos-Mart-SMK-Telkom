import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_create_result.dart';

class ComplaintRepository {
  final DioClient _client;

  ComplaintRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ComplaintCreateResult> createComplaint({
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
      if (payload is Map) {
        final id = payload['id']?.toString();
        if (id != null && id.isNotEmpty) {
          return ComplaintCreateResult(
            id: id,
            message: data['message'] as String? ?? 'Komplain berhasil dikirim',
          );
        }
      }

      throw ApiException(
        message: 'Gagal mengirim keluhan',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      message: 'Gagal mengirim keluhan',
      statusCode: response.statusCode,
    );
  }
}
