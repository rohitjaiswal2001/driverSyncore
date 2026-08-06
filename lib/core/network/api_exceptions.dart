abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'No internet connection. Please check your network.']);
}

class ServerException extends AppException {
  ServerException([super.message = 'A server error occurred. Please try again later.']);
}

class AuthException extends AppException {
  AuthException(super.message);
}

class UnauthorizedException extends AuthException {
  UnauthorizedException([super.message = 'Session expired. Please log in again.']);
}

class ValidationException extends AppException {
  final Map<String, List<String>> errors;
  ValidationException(super.message, this.errors);
}
