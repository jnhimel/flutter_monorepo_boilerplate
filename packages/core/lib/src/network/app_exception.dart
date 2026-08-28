import 'package:dio/dio.dart';

/// Base of a small, deliberately leaner exception hierarchy than a typical
/// enterprise API client (5-6 types instead of 10+ — add a new subtype only
/// when a caller actually needs to branch on it).
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'The request timed out.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error, please try again.']);
}

/// Maps a [DioException] onto our own exception hierarchy so the rest of the
/// app never has to know about Dio types.
AppException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) return const UnauthorizedException();
      if (status == 404) return const NotFoundException();
      return const ServerException();
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
    default:
      return ServerException(error.message ?? 'Unexpected error.');
  }
}
