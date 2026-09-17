import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_exception.dart';

class PaymentRepository {
  PaymentRepository(this.dio, {FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();
  final Dio dio;
  final FlutterSecureStorage storage;
  String? _storageKey;
  Future<String> _key() async {
    if (_storageKey != null) return _storageKey!;
    final user = await _request('/auth/me');
    final id = user['_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Unable to identify customer');
    }
    return _storageKey = 'stripe_checkout_$id';
  }

  Future<Map<String, dynamic>?> pending() async {
    final value = await storage.read(key: await _key());
    return value == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<Map<String, dynamic>> start(Map<String, dynamic> payload) async {
    var saved = await pending();
    if (saved == null) {
      final random = Random.secure();
      saved = {
        ...payload,
        'checkoutKey': List.generate(
          24,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
      };
      await storage.write(key: await _key(), value: jsonEncode(saved));
    }
    if (saved['items'] == null && payload['items'] != null) {
      saved = {...payload, 'checkoutKey': saved['checkoutKey']};
      await storage.write(key: await _key(), value: jsonEncode(saved));
    }
    try {
      return await _request('/payments/checkout', payload: saved);
    } on ApiException catch (error) {
      // Keep the key even when a draft is invalid: another concurrent request
      // may already have created the attempt. A corrected cart reuses that key.
      if (error.errors['checkout'] == 'not_created') {
        await storage.write(key: await _key(), value: jsonEncode({'checkoutKey': saved['checkoutKey']}));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> complete(String id) =>
      _request('/payments/checkout/$id/complete', payload: {});
  Future<void> clearRecovery() async => storage.delete(key: await _key());
  Future<void> clearCart() async {
    await dio.delete<dynamic>('/cart');
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = payload == null
          ? await dio.get<Map<String, dynamic>>(path)
          : await dio.post<Map<String, dynamic>>(path, data: payload);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid payment response');
      }
      return data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
