import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/storage/prefs_storage.dart';
import '../../core/disc/disc_variant.dart';
import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _client;

  AuthRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      ApiConfig.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'];
    final userJson = data['user'];
    final accessToken = data['accessToken'] ?? data['token'];
    final refreshToken = data['refreshToken'];

    return {
      'user': UserModel.fromJson(userJson),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  Future<Map<String, dynamic>> loginSso(String ssoToken) async {
    final response = await _client.post(
      ApiConfig.loginSso,
      data: {
        'ssoToken': ssoToken,
      },
    );

    final data = response.data['data'];
    final userJson = data['user'];
    final accessToken = data['accessToken'] ?? data['token'];
    final refreshToken = data['refreshToken'];

    return {
      'user': UserModel.fromJson(userJson),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _client.post(
      ApiConfig.register,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        'discType': PrefsStorage.instance.getSelectedDiscVariant()?.apiValue ??
            DiscVariant.influence.apiValue,
      },
    );

    final data = response.data['data'];
    final userJson = data['user'];
    final accessToken = data['accessToken'] ?? data['token'];
    final refreshToken = data['refreshToken'];

    return {
      'user': UserModel.fromJson(userJson),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(
      ApiConfig.logout,
      data: {
        'token': refreshToken,
      },
    );
  }

  Future<UserModel> updateMe({
    required String fullName,
    String? phone,
    Uint8List? localAvatarBytes,
    String? localAvatarFilename,
  }) async {
    final Map<String, dynamic> fields = {
      'fullName': fullName,
      if (phone != null) 'phone': phone,
    };

    dynamic requestData;
    Options? options;

    if (localAvatarBytes != null && localAvatarBytes.isNotEmpty) {
      final formData = FormData.fromMap(fields);
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            localAvatarBytes,
            filename: localAvatarFilename?.isNotEmpty == true ? localAvatarFilename! : 'avatar.jpg',
          ),
        ),
      );
      requestData = formData;
      options = Options(headers: {'Content-Type': 'multipart/form-data'});
    } else {
      requestData = fields;
    }

    final response = await _client.put(
      ApiConfig.userMe,
      data: requestData,
      options: options,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<String> requestPasswordReset(String email) async {
    final response = await _client.post(
      ApiConfig.forgotPassword,
      data: {
        'email': email,
        'client': 'steadiness',
      },
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return response.data['message'] as String? ??
        data['message'] as String? ??
        'Link reset password telah dikirim ke email Anda.';
  }

  Future<bool> validateResetToken(String token) async {
    final response = await _client.get(
      ApiConfig.validateResetToken,
      queryParameters: {'token': token},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return data['valid'] as bool? ?? false;
  }

  Future<String> resetPasswordWithToken({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _client.post(
      ApiConfig.resetPassword,
      data: {
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return response.data['message'] as String? ??
        'Password berhasil diperbarui.';
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      ApiConfig.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
