import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_create_result.dart';
import '../models/complaint_issue_option.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final DioClient _client;

  ComplaintRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ComplaintCreateResult> createComplaint({
    required String orderId,
    required ComplaintIssueOption issue,
    required String description,
    List<XFile> photos = const [],
  }) async {
    final formData = FormData.fromMap({
      'orderId': orderId,
      'reason': issue.toBackendReason(),
      'description': description,
    });

    for (final photo in photos) {
      final bytes = await photo.readAsBytes();
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(bytes, filename: photo.name),
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
        final id = payload['id']?.toString();
        if (id != null && id.isNotEmpty) {
          final createdAtRaw = payload['createdAt']?.toString();
          final createdAt = createdAtRaw != null
              ? DateTime.parse(createdAtRaw).toLocal()
              : DateTime.now();
          final complaintNumber = payload['complaintNumber']?.toString();
          return ComplaintCreateResult(
            id: id,
            message: data['message'] as String? ?? 'Komplain berhasil dikirim',
            createdAt: createdAt,
            ticketNumber: complaintNumber,
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
