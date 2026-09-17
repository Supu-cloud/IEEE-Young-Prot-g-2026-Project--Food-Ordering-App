import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/app/app.dart';
import 'package:food_ordering_app/core/di/app_dependencies.dart';
import 'api_client_test.dart' show FakeServer, jsonResponse;

void main() {
  testWidgets(
    'customer tabs preserve Home state and profile changes theme without replacing the tab',
    (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test',
        'user_role': 'customer',
      });
      final dependencies = AppDependencies.create(serverClientId: '');
      final requests = <String>[];
      dependencies.customerRepository.payments.dio.httpClientAdapter =
          FakeServer((request) async {
            requests.add(request.path);
            return jsonResponse(200, {
              'data': switch (request.path) {
                '/auth/me' => {'_id': 'customer', 'role': 'customer'},
                '/cart' => {'items': [], 'totalAmount': 0},
                '/users/profile' => {
                  'name': 'Customer name',
                  'email': 'customer@example.test',
                },
                _ => [],
              },
            });
          });
      await dependencies.session.restore();
      await tester.pumpWidget(FoodOrderingApp(dependencies: dependencies));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .cast<NavigationDestination>()
            .map((d) => d.label),
        ['Home', 'Restaurants', 'Orders', 'Cart', 'Wallet'],
      );
      expect(find.text('My cart'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'Keep my search');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Cart'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Wallet'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Go to Cart'), findsOneWidget);
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Customer name'), findsOneWidget);
      expect(requests.where((path) => path == '/users/profile').length, 1);
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(dependencies.theme.mode, ThemeMode.dark);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Home'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Keep my search'), findsOneWidget);
      expect(requests.where((path) => path == '/restaurants').length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
