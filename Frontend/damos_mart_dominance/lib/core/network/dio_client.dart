import 'package:dio/dio.dart';
import 'api_exception.dart';
import '../../config/api_config.dart';
import '../../config/env.dart';
import '../storage/secure_storage.dart';

class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;
  final List<void Function(String token)> _refreshQueue = [];

  // Singleton instance
  static final DioClient instance = DioClient._internal();

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: Env.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: Env.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Authorization Bearer token if available
          final token = await SecureStorage.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final requestOptions = error.requestOptions;

          // Endpoints where a 401 means "wrong credentials", NOT an expired session.
          // For these we must surface the server's message instead of trying to refresh.
          final isAuthEndpoint = requestOptions.path == ApiConfig.login ||
              requestOptions.path == ApiConfig.register ||
              requestOptions.path == ApiConfig.loginSso ||
              requestOptions.path == ApiConfig.refreshToken;

          // Trigger refresh on 401 and try to retry request (only for protected endpoints)
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final refreshToken = await SecureStorage.instance.getRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              await SecureStorage.instance.clearAll();
              return handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: ApiException.fromDioError(error),
                ),
              );
            }

            if (_isRefreshing) {
              // Queue the request until token is refreshed
              _refreshQueue.add((String token) {
                requestOptions.headers['Authorization'] = 'Bearer $token';
                _dio.fetch(requestOptions).then(
                  (res) => handler.resolve(res),
                  onError: (err) => handler.reject(err),
                );
              });
              return;
            }

            _isRefreshing = true;

            try {
              // Perform token refresh call
              final refreshResponse = await _dio.post(
                ApiConfig.refreshToken,
                data: {'token': refreshToken},
              );

              final success = refreshResponse.data['success'] ?? false;
              if (success) {
                final data = refreshResponse.data['data'];
                final newAccessToken = data['accessToken'] ?? data['token'];
                final newRefreshToken = data['refreshToken'];

                if (newAccessToken != null) {
                  await SecureStorage.instance.saveAccessToken(newAccessToken);
                  if (newRefreshToken != null) {
                    await SecureStorage.instance.saveRefreshToken(newRefreshToken);
                  }

                  // Resolve the original request
                  requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final response = await _dio.fetch(requestOptions);
                  
                  // Trigger queued requests
                  for (final callback in _refreshQueue) {
                    callback(newAccessToken);
                  }
                  _refreshQueue.clear();

                  return handler.resolve(response);
                }
              }
            } catch (e) {
              // Refresh failed, clear data and log out
              await SecureStorage.instance.clearAll();
              return handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: ApiException.fromDioError(error),
                ),
              );
            } finally {
              _isRefreshing = false;
            }
          }

          // Otherwise, wrap error and pass forward
          final apiException = ApiException.fromDioError(error);
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
            ),
          );
        },
      ),
    );
  }

  // HTTP Helper Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(message: 'Terjadi kesalahan jaringan 🌐');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      print('DEBUG DIO POST ERROR: type=${e.type}, message=${e.message}, statusCode=${e.response?.statusCode}, data=${e.response?.data}, error=${e.error}');
      if (e.error is ApiException) throw e.error!;
      throw ApiException(message: 'Terjadi kesalahan jaringan 🌐');
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(message: 'Terjadi kesalahan jaringan 🌐');
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(message: 'Terjadi kesalahan jaringan 🌐');
    }
  }
}
