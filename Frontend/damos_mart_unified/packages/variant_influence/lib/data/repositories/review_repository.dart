import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final DioClient _client;

  ReviewRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<ReviewModel> submitReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
    List<String>? localPhotoPaths,
  }) async {
    final Map<String, dynamic> fields = {
      'orderId': orderId,
      'productId': productId,
      'rating': rating.toString(), // body parsing in backend expects string/form fields
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final formData = FormData.fromMap(fields);

    if (localPhotoPaths != null && localPhotoPaths.isNotEmpty) {
      for (final path in localPhotoPaths) {
        final filename = path.split('/').last;
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(path, filename: filename),
          ),
        );
      }
    }

    final response = await _client.post(
      ApiConfig.reviews,
      data: formData,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReviewModel.fromJson(data);
  }
}
