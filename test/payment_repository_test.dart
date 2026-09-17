import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/features/customer/data/payment_repository.dart';
import 'api_client_test.dart' show FakeServer, jsonResponse;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('invalid draft can be corrected without changing its recovery key', () async {
    final dio = Dio();
    final payloads = <Map<String, dynamic>>[];
    dio.httpClientAdapter = FakeServer((request) async {
      if (request.path == '/auth/me') return jsonResponse(200, {'data': {'_id': 'customer-a'}});
      payloads.add(Map<String, dynamic>.from(request.data as Map));
      return payloads.length == 1
          ? jsonResponse(409, {'message': 'Unavailable item', 'errors': {'checkout': 'not_created'}})
          : jsonResponse(200, {'data': {'checkoutId': 'saved'}});
    });
    final repository = PaymentRepository(dio);
    await expectLater(repository.start({'items': ['unavailable']}), throwsException);
    await repository.start({'items': ['available']});
    expect(payloads[0]['checkoutKey'], payloads[1]['checkoutKey']);
    expect(payloads[1]['items'], ['available']);
  });
  test(
    'lost checkout response resumes same key and original payload after restart',
    () async {
      final dio = Dio();
      final payloads = <Map<String, dynamic>>[];
      dio.httpClientAdapter = FakeServer((request) async {
        if (request.path == '/auth/me')
          return jsonResponse(200, {
            'data': {'_id': 'customer-a'},
          });
        payloads.add(Map<String, dynamic>.from(request.data as Map));
        if (payloads.length == 1)
          return jsonResponse(503, {'message': 'temporary failure'});
        return jsonResponse(200, {
          'data': {'checkoutId': 'same-order', 'status': 'succeeded'},
        });
      });
      await expectLater(
        PaymentRepository(dio).start({'deliveryAddress': 'Original address'}),
        throwsException,
      );
      final restarted = PaymentRepository(dio);
      final result = await restarted.start({
        'deliveryAddress': 'Changed address',
      });
      expect(result['checkoutId'], 'same-order');
      expect(payloads[0], payloads[1]);
      expect(
        payloads[1]['checkoutKey'],
        matches(RegExp(r'^[a-zA-Z0-9-]{16,100}$')),
      );
      await restarted.clearRecovery();
      expect(await restarted.pending(), isNull);
    },
  );
  test('another customer cannot resume the saved customer checkout', () async {
    final dio = Dio();
    var user = 'customer-a';
    dio.httpClientAdapter = FakeServer(
      (request) async => request.path == '/auth/me'
          ? jsonResponse(200, {
              'data': {'_id': user},
            })
          : jsonResponse(200, {
              'data': {'checkoutId': 'a'},
            }),
    );
    await PaymentRepository(dio).start({'deliveryAddress': 'Private address'});
    user = 'customer-b';
    expect(await PaymentRepository(dio).pending(), isNull);
  });
}
