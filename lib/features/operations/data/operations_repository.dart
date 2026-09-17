import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';

/// All role resources use the authenticated application Dio instance.
class OperationsRepository {
  const OperationsRepository(this.dio, {this.onOrderChanged});
  final void Function()? onOrderChanged;
  final Dio dio;
  Future<dynamic> request(String path, {String method = 'GET', Map<String, dynamic>? data, Map<String, dynamic>? query}) async {
    try {
      final response = await dio.request<Map<String, dynamic>>(path, data: data, queryParameters: query, options: Options(method: method));
      if (response.data == null || !response.data!.containsKey('data')) throw const FormatException('Invalid API response.');
      return response.data!['data'];
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
  Future<Map<String, dynamic>> object(String path, {Map<String, dynamic>? query}) async => map(await request(path, query: query));
  Future<List<Map<String, dynamic>>> list(String path, {Map<String, dynamic>? query}) async => maps(await request(path, query: query));
  Future<Map<String, dynamic>> deliveryRoute(String id) => object('/deliveries/$id/route');
  Future<Map<String, dynamic>> orderStatus(String id, String status) async {
    final updated = map(await request('/orders/$id/status', method: 'PATCH', data: {'status': status}));
    if (updated['_id'] != id || !orderStatuses.contains(updated['status'])) { throw const FormatException('Invalid order update response. Refresh and retry.'); }
    onOrderChanged?.call();
    return updated;
  }
  Future<Map<String, dynamic>> deliveryStatus(String id, String status) async {
    final updated = map(await request('/deliveries/$id/status', method: 'PATCH', data: {'status': status}));
    if (updated['_id'] != id || !['assigned','accepted','picked_up','out_for_delivery','delivered','failed','rejected'].contains(updated['status'])) { throw const FormatException('Invalid delivery update response. Refresh and retry.'); }
    return updated;
  }
  Future<void> assignRider(String order, String rider) async { await request('/deliveries/orders/$order/assign', method: 'POST', data: {'riderId': rider}); }
}
Map<String, dynamic> map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> maps(dynamic value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : [];
String label(dynamic value) => (value ?? '').toString().replaceAll('_', ' ');
String money(dynamic value) => value is num ? 'LKR ${value.toStringAsFixed(2)}' : 'Not available';
String person(dynamic value) => value is Map ? (value['name'] ?? 'Not specified').toString() : value is String ? value : 'Not assigned';
String localTime(dynamic value) { final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal(); return date == null ? 'Not recorded' : date.toString().split('.').first; }
const orderStatuses = ['placed','accepted','declined','confirmed','preparing','ready_for_pickup','rider_assigned','picked_up','out_for_delivery','delivered','delivery_failed','cancelled'];
const ownerNext = {'placed':'confirmed','accepted':'confirmed','confirmed':'preparing','preparing':'ready_for_pickup'};
const riderNext = {'assigned':'picked_up','accepted':'picked_up','picked_up':'out_for_delivery','out_for_delivery':'delivered'};
