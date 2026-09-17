import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_client_test.dart' show FakeServer, jsonResponse;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/theme/app_theme.dart';
import 'package:food_ordering_app/core/theme/theme_controller.dart';
import 'package:food_ordering_app/features/customer/data/customer_repository.dart';
import 'package:food_ordering_app/features/customer/data/payment_repository.dart';
import 'package:food_ordering_app/features/customer/domain/checkout_controller.dart';
import 'package:food_ordering_app/features/customer/presentation/cart_wallet_screens.dart';

final cart = CartData.fromJson({
  'items': [
    {
      'menuItem': {
        '_id': 'food',
        'name': 'Rice',
        'price': 500,
        'restaurant': 'r',
      },
      'quantity': 2,
    },
  ],
  'groups': [
    {'restaurant': 'r', 'restaurantName': 'Rice House'},
  ],
  'totalAmount': 1000,
});
final quote = <String, dynamic>{
  'restaurantName': 'Rice House',
  'items': [
    {'name': 'Rice', 'price': 500, 'quantity': 2},
  ],
  'subtotal': 1000,
  'deliveryFee': 350,
  'totalAmount': 1350,
  'deliveryAddress': 'Colombo',
};

class CartRepo extends CustomerRepository {
  CartRepo() : super(Dio());
  CartData value = cart;
  int updates = 0;
  @override
  Future<CartData> getCart() async => value;
  @override
  Future<CartData> updateCartQuantity(String id, int quantity) async {
    updates++;
    return value;
  }

  @override
  Future<CartData> addToCart(String id, {int quantity = 1}) async => value;
}

class Gateway extends PaymentRepository {
  Gateway() : super(Dio());
  Map<String, dynamic>? saved;
  String status = 'requires_payment_method';
  bool failSave = false, loseResponse = false;
  int cleared = 0, completed = 0;
  @override
  Future<Map<String, dynamic>?> pending() async => saved;
  @override
  Future<Map<String, dynamic>> start(Map<String, dynamic> payload) async {
    saved ??= {...payload, 'checkoutKey': 'stable'};
    if (loseResponse) {
      loseResponse = false;
      throw Exception('Response lost');
    }
    return {'checkoutId': 'c', 'status': status, 'quote': quote};
  }

  @override
  Future<Map<String, dynamic>> complete(String id) async {
    completed++;
    if (failSave) throw Exception('Order save unavailable');
    return {
      'paymentStatus': 'paid',
      'cartHandled': true,
      'orders': [
        {'_id': 'o', 'paymentStatus': 'paid'},
      ],
    };
  }

  @override
  Future<void> clearRecovery() async {
    saved = null;
    cleared++;
  }

  @override
  Future<void> clearCart() async =>
      throw StateError('Must not clear the whole cart');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'checkout HTTP request contains separate address and numeric coordinates',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dio = Dio();
      Map<String, dynamic>? sent;
      dio.httpClientAdapter = FakeServer((request) async {
        if (request.path == '/auth/me') {
          return jsonResponse(200, {
            'data': {'_id': 'location-test'},
          });
        }
        expect(request.path, '/payments/checkout');
        sent = Map<String, dynamic>.from(request.data as Map);
        return jsonResponse(200, {
          'data': {'checkoutId': 'c', 'quote': quote},
        });
      });
      final controller = CheckoutController(
        CartRepo(),
        payments: PaymentRepository(dio),
      );
      await controller.initialize();
      controller.address = '  42 Temple Road  ';
      controller.selectDeliveryLocation('6.8', '79.9');
      controller.confirmDeliveryAddress(true);
      expect(await controller.review(), isTrue);
      expect(sent?['deliveryAddress'], '42 Temple Road');
      expect(sent?['deliveryLocation'], {'latitude': 6.8, 'longitude': 79.9});
    },
  );

  for (final permission in [2, 0, 1]) {
    testWidgets('GPS permission result $permission preserves manual address', (
      tester,
    ) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        return switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' => 0,
          'requestPermission' => permission,
          'getCurrentPosition' => {'latitude': 6.8, 'longitude': 79.9},
          _ => null,
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final controller = CheckoutController(CartRepo(), payments: Gateway());
      await controller.initialize();
      controller.address = '42 Temple Road';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerCartScreen(controller: controller, onWallet: () {}),
          ),
        ),
      );
      final button = find.text('Use my current location');
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(calls, contains('requestPermission'));
      expect(controller.address, '42 Temple Road');
      if (permission == 2) {
        expect(find.text('Confirm Delivery Location'), findsOneWidget);
        await tester.tap(find.text('Confirm Delivery Location'));
        await tester.pumpAndSettle();
        expect(controller.latitude, '6.8');
        expect(controller.longitude, '79.9');
        expect(controller.addressConfirmationRequired, isTrue);
      } else {
        expect(calls, isNot(contains('getCurrentPosition')));
        expect(controller.latitude, isEmpty);
        if (permission == 1) {
          expect(find.text('Open App Settings'), findsOneWidget);
        } else {
          expect(find.text('Location permission was denied.'), findsOneWidget);
        }
      }
    });
  }

  test(
    'location selection retains address and requires explicit confirmation',
    () async {
      final gateway = Gateway();
      final controller = CheckoutController(CartRepo(), payments: gateway);
      await controller.initialize();
      controller.selectDeliveryLocation('6.8', '79.9');
      expect(await controller.review(), isFalse);
      expect(controller.error, 'Please enter a delivery address.');
      expect(controller.latitude, '6.8');
      expect(gateway.saved, isNull);
      controller.address = '  12 Main Street  ';
      expect(await controller.review(), isFalse);
      expect(controller.error, contains('Please confirm'));
      await controller.quantity('food', 3);
      await controller.refreshCart();
      expect(controller.address, '  12 Main Street  ');
      expect(controller.latitude, '6.8');
      controller.confirmDeliveryAddress(true);
      controller.selectDeliveryLocation('7.1', '80.2');
      expect(controller.address, '  12 Main Street  ');
      expect(controller.addressConfirmationRequired, isTrue);
      controller.confirmDeliveryAddress(true);
      expect(await controller.review(), isTrue);
      expect(gateway.saved?['deliveryAddress'], '12 Main Street');
      expect(gateway.saved?['deliveryLocation'], {
        'latitude': 7.1,
        'longitude': 80.2,
      });
    },
  );

  testWidgets('manual address survives refresh, quantity and cart remount', (
    tester,
  ) async {
    final controller = CheckoutController(CartRepo(), payments: Gateway());
    await controller.initialize();
    Widget screen() => MaterialApp(
      home: Scaffold(
        body: CustomerCartScreen(controller: controller, onWallet: () {}),
      ),
    );
    await tester.pumpWidget(screen());
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '42 Temple Road');
    controller.selectDeliveryLocation('6.8', '79.9');
    await controller.quantity('food', 3);
    await controller.refreshCart();
    await tester.pumpAndSettle();
    expect(controller.address, '42 Temple Road');
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '42 Temple Road',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen());
    await tester.ensureVisible(find.byType(TextFormField));
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '42 Temple Road',
    );
    expect(controller.addressConfirmationRequired, isTrue);
    controller.address = 'Restored address';
    await controller.refreshCart();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Restored address',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'new checkout requires a complete valid delivery location before creating payment',
    () async {
      final gateway = Gateway();
      final controller = CheckoutController(CartRepo(), payments: gateway);
      await controller.initialize();
      controller.address = 'Text address stays intact';
      expect(await controller.review(), isFalse);
      expect(gateway.saved, isNull);
      expect(controller.error, 'Please select your delivery location.');
      controller.latitude = '6.8';
      expect(await controller.review(), isFalse);
      controller.longitude = '181';
      expect(await controller.review(), isFalse);
      controller.longitude = '79.9';
      expect(await controller.review(), isTrue);
      expect(gateway.saved?['deliveryLocation'], {
        'latitude': 6.8,
        'longitude': 79.9,
      });
      expect(gateway.saved?['deliveryAddress'], 'Text address stays intact');
    },
  );
  test(
    'review uses server quote, cancellation retains cart, retry verifies before clearing recovery',
    () async {
      final repo = CartRepo();
      final gateway = Gateway();
      final controller = CheckoutController(repo, payments: gateway);
      await controller.initialize();
      controller.address = 'Colombo';
      controller.latitude = '6.8';
      controller.longitude = '79.9';
      expect(await controller.quantity('food', 3), isTrue);
      expect(repo.updates, 1);
      expect(await controller.review(), isTrue);
      expect(controller.quote, same(quote));
      expect(controller.editable, isFalse);
      expect(
        await controller.pay((_) async => throw Exception('Card declined')),
        isFalse,
      );
      expect(controller.cart, same(cart));
      expect(gateway.cleared, 0);
      expect(gateway.completed, 0);
      expect(controller.error, contains('Card declined'));
      gateway.status = 'succeeded';
      gateway.failSave = true;
      expect(
        await controller.pay((_) async => fail('Must not charge again')),
        isFalse,
      );
      expect(gateway.cleared, 0);
      gateway.failSave = false;
      expect(
        await controller.pay((_) async => fail('Must not charge again')),
        isTrue,
      );
      expect(gateway.cleared, 1);
      expect(controller.confirmation?['paymentStatus'], 'paid');
      // New/unpurchased cart items returned by the backend survive.
      expect(controller.cart, same(cart));
    },
  );
  test(
    'lost checkout response locks edits and is recovered after restart',
    () async {
      final gateway = Gateway()..loseResponse = true;
      final first = CheckoutController(CartRepo(), payments: gateway);
      await first.initialize();
      first.address = 'Colombo';
      first.latitude = '6.8';
      first.longitude = '79.9';
      expect(await first.review(), isFalse);
      expect(first.recovering, isTrue);
      final restarted = CheckoutController(CartRepo(), payments: gateway);
      expect(await restarted.initialize(), isTrue);
      expect(restarted.quote, same(quote));
      expect(restarted.address, 'Colombo');
    },
  );
  test('processing payment never presents a second payment sheet', () async {
    final gateway = Gateway()..status = 'processing';
    final controller = CheckoutController(CartRepo(), payments: gateway);
    await controller.initialize();
    controller.address = 'Colombo';
    controller.latitude = '6.8';
    controller.longitude = '79.9';
    await controller.review();
    expect(
      await controller.pay((_) async => fail('Duplicate payment')),
      isFalse,
    );
    expect(controller.error, contains('processing'));
    expect(gateway.cleared, 0);
  });
  test('appearance persists and defaults to system', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = ThemeController();
    await first.restore();
    expect(first.mode, ThemeMode.system);
    await first.setMode(ThemeMode.dark);
    final restarted = ThemeController();
    await restarted.restore();
    expect(restarted.mode, ThemeMode.dark);
    await restarted.setMode(ThemeMode.system);
    final again = ThemeController();
    await again.restore();
    expect(again.mode, ThemeMode.system);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    expect(
      AppTheme.dark.textTheme.bodyMedium?.color,
      AppTheme.dark.colorScheme.onSurface,
    );
  });
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Cart and Wallet share the reviewed total in ${theme.brightness}',
      (tester) async {
        final controller = CheckoutController(CartRepo(), payments: Gateway());
        await controller.initialize();
        controller.address = 'Colombo';
        controller.latitude = '6.8';
        controller.longitude = '79.9';
        var index = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: IndexedStack(
                  index: index,
                  children: [
                    CustomerCartScreen(
                      controller: controller,
                      onWallet: () => setState(() => index = 1),
                    ),
                    CustomerWalletScreen(
                      controller: controller,
                      onCart: () => setState(() => index = 0),
                      onPaid: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final review = find.text('Review order');
        await tester.scrollUntilVisible(
          review,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(find.text('Total payable: LKR 1350.00'), findsOneWidget);
        final proceed = find.text('Proceed to Payment');
        await tester.ensureVisible(proceed);
        await tester.tap(proceed);
        await tester.pumpAndSettle();
        expect(find.text('Total payable: LKR 1350.00'), findsOneWidget);
        expect(find.text('Pay Now'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
