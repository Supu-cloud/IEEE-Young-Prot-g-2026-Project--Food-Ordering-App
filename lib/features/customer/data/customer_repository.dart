import 'payment_repository.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

class CustomerRepository {
  const CustomerRepository(this._dio);

  final Dio _dio;
  PaymentRepository get payments => PaymentRepository(_dio);

  Future<FoodDiscoveryData> getFoodDiscovery() async {
    final restaurants = await getRestaurants();
    final foods = <DiscoveredFood>[];
    var failedMenus = 0;
    // Limit concurrent menu requests while reusing the existing public API.
    for (var start = 0; start < restaurants.length; start += 4) {
      await Future.wait(
        restaurants.skip(start).take(4).map((restaurant) async {
          try {
            final menu = await getMenu(restaurant.id);
            foods.addAll(
              menu
                  .where((item) => item.available)
                  .map(
                    (item) =>
                        DiscoveredFood(item: item, restaurant: restaurant),
                  ),
            );
          } on Object {
            failedMenus++;
          }
        }),
      );
    }
    foods.sort((a, b) {
      final openFirst =
          (b.restaurant.isOpen ? 1 : 0) - (a.restaurant.isOpen ? 1 : 0);
      return openFirst != 0 ? openFirst : a.item.name.compareTo(b.item.name);
    });
    return FoodDiscoveryData(foods: foods, failedMenus: failedMenus);
  }

  Future<List<RestaurantData>> getRestaurants() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/restaurants');
      return _list(response).map(RestaurantData.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<RestaurantData> getRestaurant(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/restaurants/$id');
      return RestaurantData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<MenuItemData>> getMenu(String restaurantId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/menu/restaurant/$restaurantId',
      );
      return _list(response).map(MenuItemData.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CartData> getCart() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/cart');
      return CartData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CartData> addToCart(String menuItemId, {int quantity = 1}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cart/items',
        data: {'menuItem': menuItemId, 'quantity': quantity},
      );
      return CartData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CartData> updateCartQuantity(String id, int quantity) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/cart/items/$id',
        data: {'quantity': quantity},
      );
      return CartData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CartData> removeFromCart(String menuItemId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/cart/items/$menuItemId',
      );
      return CartData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OrderData> placeOrder({
    required String restaurantId,
    required List<CartItemData> items,
    required String deliveryAddress,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'restaurant': restaurantId,
          'items': items
              .map(
                (item) => {
                  'menuItem': item.menuItem.id,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'deliveryAddress': deliveryAddress,
          if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
        },
      );
      return OrderData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getTracking(String id) async {
    try {
      return _data(await _dio.get<Map<String, dynamic>>('/orders/$id'));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<OrderData>> getOrders() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders/my');
      return _list(response).map(OrderData.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OrderData> cancelOrder(String orderId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/orders/$orderId/cancel',
      );
      return OrderData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getOrderRoute(String id) async {
    try {
      return _data(await _dio.get<Map<String, dynamic>>('/orders/$id/route'));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OrderData> confirmReceipt(String orderId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/orders/$orderId/receipt',
        data: {'status': 'received'},
      );
      return OrderData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<OrderData> submitDeliveryReview({
    required String orderId,
    required int restaurantRating,
    required int riderRating,
    required int serviceRating,
    String restaurantComment = '',
    String riderComment = '',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/$orderId/delivery-review',
        data: {
          'restaurantRating': restaurantRating,
          'riderRating': riderRating,
          'serviceRating': serviceRating,
          'restaurantComment': restaurantComment,
          'comment': riderComment,
        },
      );
      return OrderData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerProfileData> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/profile');
      return CustomerProfileData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerProfileData> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/profile',
        data: {'name': name, 'phone': phone, 'address': address},
      );
      return CustomerProfileData.fromJson(_data(response));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static List<Map<String, dynamic>> _list(
    Response<Map<String, dynamic>> response,
  ) {
    final value = response.data?['data'];
    if (value is! List) {
      throw const FormatException('Invalid API list response.');
    }
    return value.whereType<Map<String, dynamic>>().toList();
  }

  static Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final value = response.data?['data'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid API object response.');
    }
    return value;
  }
}

class FoodDiscoveryData {
  const FoodDiscoveryData({required this.foods, this.failedMenus = 0});
  final List<DiscoveredFood> foods;
  final int failedMenus;
}

class DiscoveredFood {
  const DiscoveredFood({required this.item, required this.restaurant});
  final MenuItemData item;
  final RestaurantData restaurant;
}

class RestaurantData {
  final double? latitude;
  final double? longitude;
  const RestaurantData({
    this.latitude, this.longitude,
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.isOpen,
    this.imageUrl,
    this.phone = '',
    this.operatingHours = const {},
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String category;
  final bool isOpen;
  final String? imageUrl;
  final String phone;
  final Map<String, RestaurantDayHours> operatingHours;

  factory RestaurantData.fromJson(Map<String, dynamic> json) => RestaurantData(
    latitude: (json['latitude'] as num?)?.toDouble(), longitude: (json['longitude'] as num?)?.toDouble(),
    id: json['_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Restaurant',
    description: json['description'] as String? ?? '',
    address: json['address'] as String? ?? '',
    category: json['category'] as String? ?? 'Food',
    isOpen: json['isOpen'] as bool? ?? true,
    imageUrl: (json['imageUrl'] ?? json['logoUrl']) as String?,
    phone: json['phone'] as String? ?? '',
    operatingHours: (json['operatingHours'] as Map<String, dynamic>? ?? {}).map(
      (day, hours) => MapEntry(
        day,
        RestaurantDayHours.fromJson(Map<String, dynamic>.from(hours as Map)),
      ),
    ),
  );
}

class RestaurantDayHours {
  const RestaurantDayHours({
    this.open = '',
    this.close = '',
    this.closed = false,
  });
  final String open;
  final String close;
  final bool closed;
  factory RestaurantDayHours.fromJson(Map<String, dynamic> json) =>
      RestaurantDayHours(
        open: json['open'] as String? ?? '',
        close: json['close'] as String? ?? '',
        closed: json['closed'] == true,
      );
  Map<String, dynamic> toJson() => {
    'open': closed ? '' : open,
    'close': closed ? '' : close,
    'closed': closed,
  };
  String get label => closed
      ? 'Closed'
      : '$open ? $close${close.compareTo(open) < 0 ? ' (next day)' : ''}';
}

class MenuItemData {
  const MenuItemData({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.restaurantId,
    required this.available,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String restaurantId;
  final bool available;
  final String? imageUrl;

  factory MenuItemData.fromJson(Map<String, dynamic> json) => MenuItemData(
    id: json['_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Menu item',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    category: json['category'] as String? ?? 'Food',
    restaurantId: json['restaurant'] as String? ?? '',
    available: json['available'] as bool? ?? true,
    imageUrl: json['imageUrl'] as String?,
  );
}

class CartData {
  const CartData({
    required this.items,
    required this.totalAmount,
    this.restaurantId,
    this.restaurantNames = const {},
  });

  final Map<String, String> restaurantNames;
  Map<String, List<CartItemData>> get groups {
    final result = <String, List<CartItemData>>{};
    for (final item in items) {
      (result[item.menuItem.restaurantId] ??= []).add(item);
    }
    return result;
  }

  final List<CartItemData> items;
  final double totalAmount;
  final String? restaurantId;

  factory CartData.fromJson(Map<String, dynamic> json) => CartData(
    items: (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CartItemData.fromJson)
        .toList(),
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    restaurantId: json['restaurant'] as String?,
    restaurantNames: {
      for (final group
          in (json['groups'] as List? ?? []).whereType<Map<String, dynamic>>())
        group['restaurant'] as String:
            group['restaurantName'] as String? ?? 'Restaurant',
    },
  );
}

class CartItemData {
  const CartItemData({required this.menuItem, required this.quantity});

  final MenuItemData menuItem;
  final int quantity;

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    final value = json['menuItem'];
    final item = value is Map<String, dynamic>
        ? MenuItemData.fromJson(value)
        : MenuItemData(
            id: value as String? ?? '',
            name: 'Menu item',
            description: '',
            price: 0,
            category: 'Food',
            restaurantId: '',
            available: true,
          );
    return CartItemData(
      menuItem: item,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class OrderData {
  const OrderData({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.items,
    this.restaurantName,
    this.restaurantImageUrl,
    this.checkoutId,
    this.deliveryReview,
    this.deliveryRider,
  });

  final String id;
  final String status;
  final double totalAmount;
  final String deliveryAddress;
  final List<OrderItemData> items;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final String? checkoutId;
  final Map<String, dynamic>? deliveryReview;
  final Map<String, dynamic>? deliveryRider;

  factory OrderData.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'];
    return OrderData(
      id: json['_id'] as String? ?? '',
      checkoutId: json['checkoutId'] as String?,
      status: json['status'] as String? ?? 'placed',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      items: (json['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemData.fromJson)
          .toList(),
      restaurantName: restaurant is Map<String, dynamic>
          ? restaurant['name'] as String?
          : null,
      restaurantImageUrl: restaurant is Map<String, dynamic>
          ? restaurant['imageUrl'] as String?
          : null,
      deliveryReview: json['deliveryReview'] is Map
          ? Map<String, dynamic>.from(json['deliveryReview'] as Map)
          : null,
      deliveryRider: json['deliveryRider'] is Map
          ? Map<String, dynamic>.from(json['deliveryRider'] as Map)
          : null,
    );
  }
}

class OrderItemData {
  const OrderItemData({required this.name, required this.quantity});

  final String name;
  final int quantity;

  factory OrderItemData.fromJson(Map<String, dynamic> json) => OrderItemData(
    name: json['name'] as String? ?? 'Menu item',
    quantity: json['quantity'] as int? ?? 1,
  );
}

class CustomerProfileData {
  const CustomerProfileData({
    required this.name,
    required this.email,
    this.phone,
    this.address,
  });

  final String name;
  final String email;
  final String? phone;
  final String? address;

  factory CustomerProfileData.fromJson(Map<String, dynamic> json) =>
      CustomerProfileData(
        name: json['name'] as String? ?? 'Customer',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}
