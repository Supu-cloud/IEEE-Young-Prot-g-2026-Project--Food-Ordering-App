import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../domain/admin_models.dart';

class AdminRepository {
  const AdminRepository(this._dio);
  final Dio _dio;
  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) =>
      Map<String, dynamic>.from(response.data?['data'] as Map? ?? const {});

  Future<AdminDashboardData> dashboard() async => _guard(
    () async => AdminDashboardData.fromJson(
      _data(await _dio.get<Map<String, dynamic>>('/admin/dashboard')),
    ),
  );
  Future<AdminAnalyticsData> analytics({String range = '30d'}) async => _guard(
    () async => AdminAnalyticsData.fromJson(
      _data(
        await _dio.get<Map<String, dynamic>>(
          '/admin/analytics',
          queryParameters: {'range': range},
        ),
      ),
    ),
  );
  Future<List<AdminApplication>> applications({
    String status = 'pending',
    String role = '',
  }) async => _guard(() async {
    final data = _data(
      await _dio.get<Map<String, dynamic>>(
        '/admin/applications',
        queryParameters: {'status': status, if (role.isNotEmpty) 'role': role},
      ),
    );
    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AdminApplication(Map<String, dynamic>.from(item)))
        .toList();
  });
  Future<AdminApplication> application(String id) async => _guard(
    () async => AdminApplication(
      _data(await _dio.get<Map<String, dynamic>>('/admin/applications/$id')),
    ),
  );
  Future<void> approve(String id) async => _guard(() async {
    await _dio.patch<void>('/admin/applications/$id/approve');
  });
  Future<void> reject(String id, String reason) async => _guard(() async {
    await _dio.patch<void>(
      '/admin/applications/$id/reject',
      data: {'reason': reason},
    );
  });
  Future<List<Map<String, dynamic>>> users({
    String search = '',
    String role = '',
    String status = '',
  }) =>
      _list('/admin/users', {'search': search, 'role': role, 'status': status});
  Future<List<Map<String, dynamic>>> restaurants({
    String search = '',
    String open = '',
  }) => _list('/admin/restaurants', {'search': search, 'open': open});
  Future<List<Map<String, dynamic>>> orders({
    String search = '',
    String status = '',
  }) => _list('/admin/orders', {'search': search, 'status': status});
  Future<Map<String, dynamic>> report(
    String type, {
    String range = '30d',
  }) async => _guard(
    () async => _data(
      await _dio.get<Map<String, dynamic>>(
        '/admin/reports/$type',
        queryParameters: {'range': range},
      ),
    ),
  );
  Future<void> updateUserStatus(String id, String status) async =>
      _guard(() async {
        await _dio.patch<void>(
          '/admin/users/$id/status',
          data: {'status': status},
        );
      });
  Future<List<Map<String, dynamic>>> _list(
    String path,
    Map<String, dynamic> params,
  ) async => _guard(() async {
    params.removeWhere((_, value) => value == '');
    final data = _data(
      await _dio.get<Map<String, dynamic>>(path, queryParameters: params),
    );
    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  });
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
