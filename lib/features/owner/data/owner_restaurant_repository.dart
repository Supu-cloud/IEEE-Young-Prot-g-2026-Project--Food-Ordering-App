import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../customer/data/customer_repository.dart';

class RestaurantOptions {
  RestaurantOptions.fromJson(Map<String, dynamic> json)
      : categories = List<String>.from(json['categories'] as List),
        days = List<String>.from(json['days'] as List),
        limits = Map<String, int>.from(json['limits'] as Map),
        phonePattern = json['phonePattern'] as String,
        maxImageBytes = (json['image'] as Map)['maxBytes'] as int,
        imageTypes = List<String>.from((json['image'] as Map)['types'] as List);
  final List<String> categories;
  final List<String> days;
  final Map<String, int> limits;
  final String phonePattern;
  final int maxImageBytes;
  final List<String> imageTypes;
}

class OwnerRestaurantRepository extends ChangeNotifier {
  OwnerRestaurantRepository(this._dio);
  final Dio _dio;
  void refreshOrderMetrics() => notifyListeners();
  Future<RestaurantData?> getRestaurant() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/owner/restaurant');
      final data = response.data?['data'];
      return data == null ? null : RestaurantData.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
  Future<RestaurantOptions> getOptions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/restaurants/options');
      return RestaurantOptions.fromJson(Map<String, dynamic>.from(response.data!['data'] as Map));
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/owner/dashboard');
      return Map<String, dynamic>.from(response.data!['data'] as Map);
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
  Future<RestaurantData> saveRestaurant(Map<String, dynamic> payload) async {
    try {
      await _dio.put<Map<String, dynamic>>('/owner/restaurant', data: payload);
      final restaurant = await getRestaurant();
      if (restaurant == null) throw const ApiException('Saved, but unable to reload your restaurant. Please refresh.');
      notifyListeners();
      return restaurant;
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
  Future<String> uploadLogo(Uint8List bytes, String name, String mime, ProgressCallback onProgress) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/owner/restaurant/logo',
        data: FormData.fromMap({'image': MultipartFile.fromBytes(bytes, filename: name, contentType: DioMediaType.parse(mime))}),
        options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
        onSendProgress: onProgress,
      );
      return (response.data!['data'] as Map)['imageUrl'] as String;
    } on DioException catch (error) { throw ApiException.fromDio(error); }
  }
}
