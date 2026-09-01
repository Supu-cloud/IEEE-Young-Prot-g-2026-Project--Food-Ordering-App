import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final body = error.response?.data;
    final serverMessage = body is Map<String, dynamic> ? body['message'] : null;
    return ApiException(
      serverMessage is String ? serverMessage : 'Unable to connect. Please try again.',
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
