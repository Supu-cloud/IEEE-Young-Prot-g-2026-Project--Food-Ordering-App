import 'package:flutter/foundation.dart';
import '../../../core/config/map_config.dart';
import '../../../core/network/api_exception.dart';
import '../data/customer_repository.dart';
import '../data/payment_repository.dart';

/// Session-scoped view of the server cart and its immutable checkout quote.
class CheckoutController extends ChangeNotifier {
  CheckoutController(this.repository, {PaymentRepository? payments})
    : payments = payments ?? repository.payments;
  final CustomerRepository repository;
  final PaymentRepository payments;
  CartData? cart;
  Map<String, dynamic>? attempt;
  Map<String, dynamic>? confirmation;
  Map<String, dynamic>? get quote => attempt?['quote'] as Map<String, dynamic>?;
  String address = '';
  String latitude = '';
  String longitude = '';
  bool addressConfirmationRequired = false;

  void selectDeliveryLocation(String lat, String lng) {
    if (!editable) return;
    latitude = lat;
    longitude = lng;
    addressConfirmationRequired = true;
    error = null;
    _changed();
  }

  void confirmDeliveryAddress(bool confirmed) {
    if (!editable) return;
    addressConfirmationRequired = !confirmed;
    _changed();
  }

  String? error;
  bool busy = false;
  bool initialized = false;
  bool recovering = false;
  bool _disposed = false;
  int get itemCount =>
      cart?.items.fold<int>(0, (sum, line) => sum + line.quantity) ?? 0;
  bool get editable => initialized && !busy && !recovering;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> _run(String operation, Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    _changed();
    try {
      await action();
      return true;
    } catch (failure) {
      error = failure is ApiException
          ? failure.message
          : '$operation: $failure';
      if (kDebugMode) {
        debugPrint('[Checkout] $operation failed (${failure.runtimeType})');
      }
      return false;
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<bool> initialize() => _run('Load cart / saved payment', () async {
    // Resolve recovery first: an uncertain payment must never become a new one.
    final saved = await payments.pending();
    recovering = saved?['items'] != null;
    if (recovering) {
      address = saved?['deliveryAddress'] as String? ?? '';
      final location = saved?['deliveryLocation'];
      if (location is Map) {
        latitude = location['latitude']?.toString() ?? '';
        longitude = location['longitude']?.toString() ?? '';
      }
      attempt = await payments.start(saved!);
    }
    cart = await repository.getCart();
    initialized = true;
  });

  Future<bool> refreshCart() => _run('Load cart', () async {
    cart = await repository.getCart();
  });

  Future<void> add(String id) async {
    if (!editable) {
      throw StateError(
        recovering
            ? 'Finish the saved payment in Wallet before changing the cart.'
            : 'Please wait for the cart to finish loading.',
      );
    }
    final ok = await _run('Add to cart', () async {
      cart = await repository.addToCart(id);
      confirmation = null;
    });
    if (!ok) throw StateError(error ?? 'Cart could not be updated.');
  }

  Future<bool> quantity(String id, int value) async {
    if (!editable) return false;
    return _run('Update cart', () async {
      cart = value < 1
          ? await repository.removeFromCart(id)
          : await repository.updateCartQuantity(id, value);
      confirmation = null;
    });
  }

  Future<bool> review() => _run('Review order', () async {
    if (!initialized) {
      throw StateError('Retry loading your saved payment first.');
    }
    if (!recovering && (cart?.items.isEmpty ?? true)) {
      throw const ApiException('Please add food to your cart.');
    }
    if (!recovering && address.trim().isEmpty) {
      throw const ApiException('Please enter a delivery address.');
    }
    final point = parseCoordinates({
      'latitude': double.tryParse(latitude),
      'longitude': double.tryParse(longitude),
    });
    if (!recovering && point == null) {
      throw const ApiException('Please select your delivery location.');
    }
    if (!recovering && addressConfirmationRequired) {
      throw const ApiException(
        'Please confirm the delivery address matches your selected location.',
      );
    }
    final location = point == null
        ? null
        : {'latitude': point.latitude, 'longitude': point.longitude};
    confirmation = null;
    try {
      attempt = await payments.start({
        'items': cart!.items
            .map(
              (line) => {
                'menuItem': line.menuItem.id,
                'quantity': line.quantity,
              },
            )
            .toList(),
        'deliveryAddress': address.trim(),
        if (location != null) 'deliveryLocation': location,
      });
    } finally {
      // Includes a lost HTTP response after the backend created an intent.
      final saved = await payments.pending();
      recovering = saved?['items'] != null;
    }
  });

  Future<bool> pay(
    Future<void> Function(Map<String, dynamic>) presentPayment,
  ) => _run('Payment / order confirmation', () async {
    if (attempt == null || !recovering) {
      throw StateError('Review the cart before paying.');
    }
    final current = await payments.start({});
    attempt = current;
    if (current['status'] == 'processing') {
      throw StateError(
        'Payment is processing. Retry verification shortly; do not pay again.',
      );
    }
    if (current['status'] != 'succeeded') await presentPayment(current);
    if (_disposed)
      throw StateError(
        'Session changed. Resume verification after signing in.',
      );
    final result = await payments.complete(current['checkoutId'] as String);
    final orders = (result['orders'] as List? ?? [result])
        .whereType<Map>()
        .toList();
    if (orders.isEmpty ||
        result['paymentStatus'] != 'paid' ||
        orders.any(
          (order) =>
              order['_id'] is! String || order['paymentStatus'] != 'paid',
        )) {
      throw const FormatException(
        'Paid orders have not been confirmed. Retry verification.',
      );
    }
    // Only the backend may consume purchased quantities; never DELETE /cart here.
    confirmation = result;
    try {
      await payments.clearRecovery();
      recovering = false;
      attempt = null;
    } catch (_) {
      error =
          'Payment confirmed. Saved-payment cleanup failed; retry verification in Wallet. Do not pay again.';
    }
    try {
      cart = await repository.getCart();
    } catch (_) {
      cart = null;
      error =
          'Payment confirmed. Could not refresh the cart; retry loading it.';
    }
  });
}
