import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  factory ApiException.fromDioError(DioException dioError) {
    String message = 'Oops! Terjadi kesalahan koneksi internet 😅';
    int? statusCode = dioError.response?.statusCode;
    dynamic details;

    switch (dioError.type) {
      case DioExceptionType.cancel:
        message = 'Koneksi ke server dibatalkan 🛑';
        break;
      case DioExceptionType.connectionTimeout:
        message = 'Koneksi ke server habis waktu (Timeout) ⏰';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Waktu menerima data dari server habis ⏰';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Waktu mengirim data ke server habis ⏰';
        break;
      case DioExceptionType.badResponse:
        final responseData = dioError.response?.data;
        String? errorCode;
        if (responseData != null && responseData is Map) {
          // Backend error shape: { success: false, error: { code, message, details } }
          final errorObj = responseData['error'];
          if (errorObj is Map) {
            message = errorObj['message'] ??
                responseData['message'] ??
                'Ada masalah di server nih 😅';
            details = errorObj['details'] ??
                responseData['errors'] ??
                responseData['details'];
            final rawCode = errorObj['code'];
            if (rawCode != null) {
              errorCode = rawCode.toString();
            }
          } else {
            message = responseData['message'] ?? 'Ada masalah di server nih 😅';
            details = responseData['errors'] ?? responseData['details'];
          }
        } else {
          message = 'Server merespon dengan status error: $statusCode 💥';
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          code: errorCode,
          details: details,
        );
      case DioExceptionType.connectionError:
        message = 'Gagal terhubung ke server. Pastikan server aktif dan terhubung ke jaringan! 🌐';
        break;
      default:
        message = 'Terjadi kesalahan tidak terduga: ${dioError.message}';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => message;
}
