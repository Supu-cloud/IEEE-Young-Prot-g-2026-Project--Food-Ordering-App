import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/network/api_exception.dart';
import 'package:food_ordering_app/features/customer/data/customer_repository.dart';
import 'package:food_ordering_app/core/network/api_client.dart';
import 'api_client_test.dart' show MemoryTokens, FakeServer, jsonResponse;

void main() {
  test('Home uses exactly one api prefix for restaurants and menus', () async {
    final client = ApiClient(MemoryTokens());
    client.dio.options.baseUrl = 'http://192.168.1.37:5000/api';
    final urls = <String>[];
    client.dio.httpClientAdapter = FakeServer((request) async {
      urls.add(request.uri.toString());
      return jsonResponse(200, {
        'data': request.path == '/restaurants'
            ? [
                {'_id': 'r1'},
              ]
            : [],
      });
    });
    await CustomerRepository(client.dio).getFoodDiscovery();
    expect(urls, [
      'http://192.168.1.37:5000/api/restaurants',
      'http://192.168.1.37:5000/api/menu/restaurant/r1',
    ]);
  });

  for (final entry in {
    401: 'authentication',
    403: 'permission',
    404: 'route',
    500: 'server',
  }.entries) {
    test('HTTP ${entry.key} is not a connection failure even without JSON', () {
      final request = RequestOptions(path: '/restaurants');
      final error = ApiException.fromDio(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: request,
            statusCode: entry.key,
            data: '<html>Error</html>',
          ),
        ),
      );
      expect(error.statusCode, entry.key);
      expect(error.message, contains(entry.value));
      expect(error.message, isNot(contains('Cannot reach')));
    });
  }
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  ]) {
    test('$type has a timeout message', () {
      expect(
        ApiException.fromDio(
          DioException(
            requestOptions: RequestOptions(path: '/restaurants'),
            type: type,
          ),
        ).message,
        contains('timed out'),
      );
    });
  }
  test('connection failure retains network message', () {
    expect(
      ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/restaurants'),
          type: DioExceptionType.connectionError,
        ),
      ).message,
      startsWith('Cannot reach'),
    );
  });
}
