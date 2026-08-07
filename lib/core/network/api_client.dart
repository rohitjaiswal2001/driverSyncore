import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';

/// The single HTTP client for the whole app.
///
/// Every network call goes through here - our backend, document downloads and
/// third-party APIs alike - so timeouts, headers, logging and error
/// translation are defined in exactly one place. Nothing else in the app
/// should construct a [Dio].
class ApiClient {
  /// Talks to our backend: carries [ApiConstants.baseUrl] and the auth token.
  final Dio _dio;

  /// Talks to everyone else (document storage, Google APIs). Deliberately a
  /// separate transport: those URLs are absolute and must never be handed our
  /// Authorization header.
  final Dio _externalDio;

  void Function(String path)? onUnauthorized;

  static const List<String> _whitelistedAuthPaths = [
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.forgotPassword,
    ApiConstants.resetPassword,
    ApiConstants.resendOtp,
    ApiConstants.verifyOtp,
    ApiConstants.logout,
  ];

  bool _isWhitelisted(String path) {
    final parsedPath = Uri.tryParse(path)?.path ?? path;
    final lowerPath = parsedPath.toLowerCase();
    return _whitelistedAuthPaths.any(
      (endpoint) =>
          lowerPath.endsWith(endpoint.toLowerCase()) ||
          lowerPath.contains(endpoint.toLowerCase()),
    );
  }

  /// Both transports are optional so tests can hand in their own; in the app
  /// they are built and configured right here.
  ApiClient({Dio? dio, Dio? externalDio})
    : _dio = dio ?? Dio(),
      _externalDio = externalDio ?? Dio() {
    _applyTimeouts(_dio.options);
    _dio.options.baseUrl = ApiConstants.baseUrl;
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

    _applyTimeouts(_externalDio.options);
    // No base URL, no default headers, and bodies stay out of the log: these
    // responses are PDF bytes and full route payloads.
    _externalDio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );
  }

  /// The one place any request in the app gets its time limits. All three
  /// matter: `send` bounds uploads (the multipart profile image), `receive`
  /// bounds slow responses, `connect` bounds a server that never answers.
  static void _applyTimeouts(BaseOptions options) {
    options.connectTimeout = ApiConstants.apiTimeout;
    options.sendTimeout = ApiConstants.apiTimeout;
    options.receiveTimeout = ApiConstants.apiTimeout;
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

  /// GET against an absolute third-party URL - document hosts, Google APIs.
  ///
  /// Same timeouts and error translation as the rest of the app, but without
  /// our base URL or auth token, and a failure here can never sign the driver
  /// out: somebody else's 401 says nothing about our session.
  Future<Response<T>> getExternal<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _externalDio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, isExternal: true);
    }
  }

  Exception _handleDioError(DioException error, {bool isExternal = false}) {
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
              final requestPath = error.requestOptions.path;
              if (!isExternal && !_isWhitelisted(requestPath)) {
                onUnauthorized?.call(requestPath);
              }
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
