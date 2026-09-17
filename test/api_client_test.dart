import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/network/api_client.dart';
import 'package:food_ordering_app/core/storage/token_storage.dart';

class MemoryTokens extends TokenStorage {
  String? access = 'expired';
  String? refresh = 'refresh';
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class FakeServer implements HttpClientAdapter {
  FakeServer(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  test(
    'concurrent expired requests share one refresh and retry with new token',
    () async {
      final storage = MemoryTokens();
      final client = ApiClient(storage);
      var refreshes = 0;
      client.dio.httpClientAdapter = FakeServer((request) async {
        if (request.path == '/auth/refresh') {
          refreshes++;
          expect(request.headers['Authorization'], isNull);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse(200, {
            'data': {
              'accessToken': 'new',
              'refreshToken': 'next',
              'user': {'role': 'customer'},
            },
          });
        }
        return request.headers['Authorization'] == 'Bearer new'
            ? jsonResponse(200, {'data': []})
            : jsonResponse(401, {'message': 'expired'});
      });
      final results = await Future.wait([
        client.dio.get('/orders/my'),
        client.dio.get('/cart'),
      ]);
      expect(results.every((response) => response.statusCode == 200), isTrue);
      expect(refreshes, 1);
      expect(storage.refresh, 'next');
    },
  );

  test('rejected refresh clears credentials and expires the session', () async {
    final storage = MemoryTokens();
    var expired = false;
    final client = ApiClient(
      storage,
      onSessionExpired: () async {
        expired = true;
      },
    );
    client.dio.httpClientAdapter = FakeServer(
      (_) async => jsonResponse(401, {'message': 'invalid'}),
    );
    await expectLater(
      client.dio.get('/orders/my'),
      throwsA(isA<DioException>()),
    );
    expect(storage.access, isNull);
    expect(expired, isTrue);
  });

  test('temporary refresh failure retains credentials for recovery', () async {
    final storage = MemoryTokens();
    final client = ApiClient(storage);
    client.dio.httpClientAdapter = FakeServer(
      (request) async => jsonResponse(
        request.path == '/auth/refresh' ? 503 : 401,
        {'message': 'unavailable'},
      ),
    );
    await expectLater(client.dio.get('/cart'), throwsA(isA<DioException>()));
    expect(storage.refresh, 'refresh');
  });

  test('incorrect login credentials do not trigger token refresh', () async {
    final client = ApiClient(MemoryTokens());
    var requests = 0;
    client.dio.httpClientAdapter = FakeServer((request) async {
      requests++;
      expect(request.path, '/auth/login');
      return jsonResponse(401, {'message': 'invalid login'});
    });
    await expectLater(
      client.dio.post('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(requests, 1);
  });
}
