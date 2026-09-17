import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const {}});
  final Map<String, String> errors;
  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final body = error.response?.data;
    final serverMessage = body is Map<String, dynamic> ? body['message'] : null;
    final status = error.response?.statusCode;
    // A response proves the server was reached, regardless of exception type.
    final String message;
    if (status != null) {
      message = switch (status) {
        401 =>
          'Your session has expired or authentication failed. Please sign in again.',
        403 => 'You do not have permission to access this resource.',
        404 =>
          serverMessage is String
              ? serverMessage
              : 'The requested API route was not found (404).',
        >= 500 =>
          serverMessage is String
              ? 'Server error ($status): $serverMessage'
              : 'The server encountered an error ($status). Please try again.',
        _ =>
          serverMessage is String
              ? serverMessage
              : 'Request failed ($status). Please try again.',
      };
    } else {
      message = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'The backend request timed out. Please try again.',
        DioExceptionType.connectionError =>
          'Cannot reach the backend. Check that the server is running and the phone is on the same Wi-Fi network.',
        DioExceptionType.cancel =>
          'The request was cancelled. Please try again.',
        DioExceptionType.badCertificate =>
          'The backend security certificate could not be verified.',
        _ => 'The request failed unexpectedly. Please try again.',
      };
    }
    return ApiException(
      message,
      statusCode: error.response?.statusCode,
      errors: body is Map<String, dynamic> && body['errors'] is Map
          ? (body['errors'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
    );
  }

  @override
  String toString() => message;
}
