import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  void Function()? onUnauthorized;

  ApiClient(this._dio) {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 105);
    _dio.options.receiveTimeout = const Duration(seconds: 105);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
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
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection timeout with server. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          final statusCode = response.statusCode;
          final responseData = response.data;

          if (responseData is Map<String, dynamic>) {
            if (statusCode == 422 && responseData.containsKey('errors')) {
              final message =
                  responseData['message'] as String? ?? 'Validation error';
              final errorsMap = <String, List<String>>{};
              final rawErrors = responseData['errors'];
              if (rawErrors is Map<String, dynamic>) {
                rawErrors.forEach((key, val) {
                  if (val is List) {
                    errorsMap[key] = val.map((e) => e.toString()).toList();
                  } else {
                    errorsMap[key] = [val.toString()];
                  }
                });
              }
              return ValidationException(message, errorsMap);
            }

            final message =
                responseData['message'] as String? ??
                responseData['error'] as String? ??
                'An error occurred: $statusCode';

            if (statusCode == 401) {
              onUnauthorized?.call();
              return UnauthorizedException(message);
            }

            if (statusCode == 403) {
              return AuthException(message);
            }

            return ServerException(message);
          }

          return ServerException('Server returned code: $statusCode');
        }
        return ServerException();

      case DioExceptionType.cancel:
        return NetworkException('Request to server was cancelled.');

      case DioExceptionType.unknown:
      default:
        if (error.message != null &&
            error.message!.contains('SocketException')) {
          return NetworkException(
            'No internet connection. Please verify your connection.',
          );
        }
        return ServerException(
          'An unexpected error occurred: ${error.message}',
        );
    }
  }
}
