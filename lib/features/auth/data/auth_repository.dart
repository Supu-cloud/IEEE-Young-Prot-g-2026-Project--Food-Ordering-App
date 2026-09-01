import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import '../domain/user_role.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) throw const FormatException('Invalid login response.');
      return AuthSession.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> register({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final path = switch (role) {
      UserRole.customer => '/auth/signup',
      UserRole.restaurantOwner => '/auth/signup/restaurant-owner',
      UserRole.deliveryRider => '/auth/signup/delivery-rider',
    };
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone?.trim().isNotEmpty ?? false) 'phone': phone!.trim(),
        if (address?.trim().isNotEmpty ?? false) 'address': address!.trim(),
      });
      return response.data?['message'] as String? ?? 'Account created successfully';
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
