import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/features/customer/data/customer_repository.dart';
import 'package:food_ordering_app/features/customer/data/payment_repository.dart';
import 'package:food_ordering_app/features/customer/presentation/cart_wallet_screens.dart';
import 'package:food_ordering_app/features/customer/domain/checkout_controller.dart';

final quote = <String, dynamic>{
  'subtotal': 1400,
  'deliveryFee': 700,
  'totalAmount': 2100,
  'deliveryAddress': 'Test address',
  'groups': [
    {
      'restaurant': 'a',
      'restaurantName': 'Rice House',
      'subtotal': 1000,
      'deliveryFee': 350,
      'totalAmount': 1350,
      'items': [],
    },
    {
      'restaurant': 'b',
      'restaurantName': 'Pizza House',
      'subtotal': 400,
      'deliveryFee': 350,
      'totalAmount': 750,
      'items': [],
    },
  ],
};

class FakePayments extends PaymentRepository {
  FakePayments() : super(Dio());
  int cartClears = 0, recoveryClears = 0;
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> pending() async => {
    'deliveryAddress': 'Test address',
    'items': [],
  };
  @override
  Future<Map<String, dynamic>> start(Map<String, dynamic> payload) async => {
    'checkoutId': 'checkout',
    'status': 'succeeded',
    'quote': quote,
  };
  @override
  Future<Map<String, dynamic>> complete(String id) async {
    if (fail) throw Exception('Save failed');
    return {
      'checkoutId': id,
      'paymentStatus': 'paid',
      'cartHandled': true,
      'orders': [
        {
          '_id': 'order-a',
          'restaurant': 'a',
          'paymentStatus': 'paid',
          'totalAmount': 1350,
        },
        {
          '_id': 'order-b',
          'restaurant': 'b',
          'paymentStatus': 'paid',
          'totalAmount': 750,
        },
      ],
    };
  }

  @override
  Future<void> clearCart() async {
    cartClears++;
  }

  @override
  Future<void> clearRecovery() async {
    recoveryClears++;
  }
}

class FakeCustomer extends CustomerRepository {
  FakeCustomer(this.gateway) : super(Dio());
  final FakePayments gateway;
  @override
  Future<CartData> getCart() async => const CartData(items: [], totalAmount: 0);
  @override
  PaymentRepository get payments => gateway;
}

void main() {
  test(
    'cart parses multiple restaurant groups without requiring a single restaurant',
    () {
      final cart = CartData.fromJson({
        'items': [
          {
            'menuItem': {'_id': '1', 'restaurant': 'a', 'price': 500},
            'quantity': 2,
          },
          {
            'menuItem': {'_id': '2', 'restaurant': 'b', 'price': 400},
            'quantity': 1,
          },
        ],
        'groups': [
          {'restaurant': 'a', 'restaurantName': 'Rice House'},
          {'restaurant': 'b', 'restaurantName': 'Pizza House'},
        ],
        'totalAmount': 1400,
      });
      expect(cart.restaurantId, isNull);
      expect(cart.groups.length, 2);
      expect(cart.restaurantNames['b'], 'Pizza House');
    },
  );
  testWidgets(
    'paid combined checkout opens separate tracking links without clearing other cart items',
    (tester) async {
      final gateway = FakePayments();
      final controller = CheckoutController(FakeCustomer(gateway));
      await controller.initialize();
      var openedOrders = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerWalletScreen(
              controller: controller,
              onCart: () {},
              onPaid: () {
                openedOrders = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Verify payment');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Payment confirmed'), findsOneWidget);
      expect(openedOrders, isTrue);
      expect(gateway.cartClears, 0);
      expect(gateway.recoveryClears, 1);
    },
  );
  testWidgets(
    'failed order persistence retains recovery and never clears cart',
    (tester) async {
      final gateway = FakePayments()..fail = true;
      final controller = CheckoutController(FakeCustomer(gateway));
      await controller.initialize();
      var openedOrders = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerWalletScreen(
              controller: controller,
              onCart: () {},
              onPaid: () {
                openedOrders = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Verify payment');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(gateway.cartClears, 0);
      expect(gateway.recoveryClears, 0);
      expect(find.textContaining('Save failed'), findsOneWidget);
      expect(openedOrders, isFalse);
      expect(controller.recovering, isTrue);
    },
  );
}
