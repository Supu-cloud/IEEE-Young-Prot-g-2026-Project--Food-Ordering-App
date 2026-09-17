import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../storage/token_storage.dart';
import '../../features/auth/domain/auth_session.dart';

class ApiClient {
  ApiClient(
    this._tokenStorage, {
    this.onSessionExpired,
    this.onSessionRefreshed,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: AppConfig.apiBaseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           headers: {'Accept': 'application/json'},
         ),
       ) {
    // Before authentication so failed attempts and refresh requests are visible.
    if (kDebugMode &&
        const bool.fromEnvironment('API_DEBUG_LOGS', defaultValue: true)) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[API] -> ${options.method} ${_safeUrl(options)}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[API] <- ${response.requestOptions.method} ${_safeUrl(response.requestOptions)} status=${response.statusCode} ${_bodySummary(response.data)}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              '[API] !! ${error.requestOptions.method} ${_safeUrl(error.requestOptions)} status=${error.response?.statusCode ?? "none"} type=${error.type.name} exception=${error.error.runtimeType} message=${_safeMessage(error.message)} ${_bodySummary(error.response?.data)}',
            );
            handler.next(error);
          },
        ),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path.startsWith('/auth/') && options.path != '/auth/me') {
            handler.next(options);
            return;
          }
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['sessionRetry'] == true ||
              (request.path.startsWith('/auth/') &&
                  request.path != '/auth/me')) {
            handler.next(error);
            return;
          }
          try {
            final current = await _tokenStorage.readAccessToken();
            if (current == null ||
                request.headers['Authorization'] == 'Bearer $current') {
              await (_refreshing ??= _refresh().whenComplete(
                () => _refreshing = null,
              ));
            }
            final token = await _tokenStorage.readAccessToken();
            if (token == null) {
              handler.next(error);
              return;
            }
            request.extra['sessionRetry'] = true;
            request.headers['Authorization'] = 'Bearer $token';
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (refreshError) {
            handler.next(refreshError);
          } on Object {
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio dio;
  final Future<void> Function()? onSessionExpired;
  final Future<void> Function(AuthSession)? onSessionRefreshed;
  Future<void>? _refreshing;

  static String _safeUrl(RequestOptions options) {
    final uri = options.uri;
    // Keep the complete endpoint; query values and user-info can be credentials.
    return uri
        .replace(userInfo: '', query: uri.hasQuery ? '[redacted]' : null)
        .toString();
  }

  static String _safeMessage(String? message) => (message ?? '').replaceAll(
    RegExp(
      r'https?://\S+|Bearer\s+\S+|(?:token|password|secret|key)\s*[:=]\s*\S+',
      caseSensitive: false,
    ),
    '[redacted]',
  );

  // Log response structure only; auth/payment/profile bodies may contain secrets.
  static String _bodySummary(dynamic body) {
    if (body is Map && body['data'] is List) {
      return 'body={data: List(length=${(body['data'] as List).length})}';
    }
    return 'bodyType=${body.runtimeType}';
  }

  Future<void> _refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expire();
      return;
    }
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid session response.');
      }
      final session = AuthSession.fromJson(data);
      if (await _tokenStorage.readRefreshToken() != refreshToken) return;
      if (onSessionRefreshed != null) {
        await onSessionRefreshed!(session);
      } else {
        await _tokenStorage.saveSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          role: session.role.apiValue,
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _expire();
      }
      rethrow;
    }
  }

  Future<void> _expire() async {
    await _tokenStorage.clear();
    await onSessionExpired?.call();
  }
}
