import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final DioClient _client;

  ComplaintRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ComplaintModel> submitComplaint({
    required String orderId,
    required ComplaintReason reason,
    required String description,
    required List<XFile> photos,
  }) async {
    final formData = FormData.fromMap({
      'orderId': orderId,
      'reason': reason.apiValue,
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
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ComplaintModel.fromJson(data);
  }

  Future<List<ComplaintModel>> getMyComplaints() async {
    final response = await _client.get(ApiConfig.myComplaints);
    final dataList = response.data['data'] as List? ?? [];
    return dataList.map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ReturnScheduleModel> scheduleReturn({
    required String complaintId,
    required DateTime returnDate,
    required ReturnTimeSlot timeSlot,
  }) async {
    final response = await _client.post(
      ApiConfig.scheduleReturn(complaintId),
      data: {
        'returnDate': returnDate.toIso8601String(),
        'timeSlot': timeSlot.apiValue,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReturnScheduleModel.fromJson(data);
  }

  Future<List<ReturnScheduleModel>> getMyReturnSchedules() async {
    final response = await _client.get(ApiConfig.myReturnSchedules);
    final dataList = response.data['data'] as List? ?? [];
    return dataList.map((json) => ReturnScheduleModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
