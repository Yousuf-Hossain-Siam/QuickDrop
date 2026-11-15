import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pos_background_upload_download/core/constants/api_constants.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          final request = error.requestOptions;
          final statusCode = error.response?.statusCode;

          if (statusCode == 401) {
            await clearToken();
          }

          if (_shouldRetry(request, error)) {
            final retryCount = request.extra[_retryCountKey] as int? ?? 0;
            request.extra[_retryCountKey] = retryCount + 1;
            await Future<void>.delayed(
              Duration(milliseconds: 300 * (1 << retryCount)),
            );
            try {
              final response = await dio.fetch<dynamic>(request);
              handler.resolve(response);
            } on DioException catch (retryError) {
              handler.next(retryError);
            }
            return;
          }

          handler.next(error);
        },
      ),
    );
  }

  static const _retryCountKey = 'api_retry_count';
  static const _maxRetries = 2;

  final Dio dio;
  static const _tokenKey = 'auth_token';

  void setToken(String token, {String tokenType = 'Bearer'}) {
    dio.options.headers['Authorization'] = '$tokenType $token';
  }

  Future<String?> restoreToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    setToken(token);
    return token;
  }

  Future<String> login(String username, String password) async {
    final response = await dio.post(
      ApiConstants.tokenPath,
      data: {'username': username, 'password': password},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Accept': Headers.jsonContentType},
      ),
    );
    if (response.data is! Map) {
      throw const FormatException('The server returned an invalid response.');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final token = data['token'] ?? data['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('The server returned an invalid token.');
    }
    final tokenType = data['token_type'];
    setToken(token, tokenType: tokenType is String ? tokenType : 'Bearer');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    return token;
  }

  Future<void> clearToken() async {
    dio.options.headers.remove('Authorization');
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  static bool _shouldRetry(RequestOptions request, DioException error) {
    final retryCount = request.extra[_retryCountKey] as int? ?? 0;
    if (retryCount >= _maxRetries ||
        request.method != 'GET' &&
            request.method != 'HEAD' &&
            request.method != 'OPTIONS') {
      return false;
    }

    final statusCode = error.response?.statusCode;
    final transientStatus =
        statusCode == 408 ||
        statusCode == 429 ||
        statusCode != null && statusCode >= 500;
    final transientError =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout;
    return transientStatus || transientError;
  }

  static String userMessageFor(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Invalid username or password.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Unable to reach the server. Check your connection and try again.';
    }
    if (error.response?.statusCode case final status? when status >= 500) {
      return 'The server is temporarily unavailable. Please try again later.';
    }
    return 'The request could not be completed. Please try again.';
  }
}
