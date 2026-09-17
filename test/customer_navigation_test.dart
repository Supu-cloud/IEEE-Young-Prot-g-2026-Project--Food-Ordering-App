import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/app/app.dart';
import 'package:food_ordering_app/core/di/app_dependencies.dart';
import 'package:food_ordering_app/features/auth/domain/user_role.dart';

import 'api_client_test.dart' show FakeServer, jsonResponse;

Future<void> pumpUi(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 500),
}) async {
  await tester.pump();
  await tester.pump(duration);
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(step);

    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure(
    'Expected widget was not found after waiting: $finder',
  );
}

void main() {
  testWidgets(
    'customer tabs preserve Home state and profile changes theme without replacing the tab',
    (tester) async {
      debugPrint('STEP 1 - Test started');

      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.reset);

      debugPrint('STEP 2 - Screen size configured');

      // Mock secure storage BEFORE creating AppDependencies.
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test',
        'user_role': 'customer',
      });

      debugPrint('STEP 3 - Secure storage mocked');

      final dependencies = AppDependencies.create(
        serverClientId: '',
      );

      debugPrint('STEP 4 - Dependencies created');

      final requests = <String>[];

      // Attach the fake server to the shared API client.
      dependencies.client.dio.httpClientAdapter = FakeServer(
        (request) async {
          debugPrint('FAKE REQUEST -> ${request.path}');

          requests.add(request.path);

          return jsonResponse(
            200,
            {
              'data': switch (request.path) {
                '/auth/me' => {
                    '_id': 'customer',
                    'role': 'customer',
                  },
                '/cart' => {
                    'items': [],
                    'totalAmount': 0,
                  },
                '/users/profile' => {
                    'name': 'Customer name',
                    'email': 'customer@example.test',
                  },
                '/restaurants' => [],
                _ => [],
              },
            },
          );
        },
      );

      debugPrint('STEP 5 - Fake server configured');

      // This test checks navigation behaviour, not session restoration.
      dependencies.session.role = UserRole.customer;

      debugPrint('STEP 6 - Customer session ready');

      await tester.pumpWidget(
        FoodOrderingApp(
          dependencies: dependencies,
        ),
      );

      debugPrint('STEP 7 - FoodOrderingApp pumped');

      await pumpUntilFound(
        tester,
        find.byType(NavigationBar),
      );

      debugPrint('STEP 8 - NavigationBar found');

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(
        navigationBar.destinations
            .cast<NavigationDestination>()
            .map((destination) => destination.label),
        [
          'Home',
          'Restaurants',
          'Orders',
          'Cart',
          'Wallet',
        ],
      );

      debugPrint('STEP 9 - Navigation destinations verified');

      await pumpUntilFound(
        tester,
        find.byType(TextField),
      );

      debugPrint('STEP 10 - Search TextField found');

      await tester.enterText(
        find.byType(TextField).first,
        'Keep my search',
      );

      await pumpUi(tester);

      debugPrint('STEP 11 - Search text entered');

      // Open Cart tab.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Cart'),
        ),
      );

      await pumpUi(tester);

      debugPrint('STEP 12 - Cart tab tapped');

      expect(
        tester
            .widget<NavigationBar>(
              find.byType(NavigationBar),
            )
            .selectedIndex,
        3,
      );

      debugPrint('STEP 13 - Cart tab verified');

      // Open Wallet tab.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Wallet'),
        ),
      );

      await pumpUi(tester);

      debugPrint('STEP 14 - Wallet tab tapped');

      expect(
        tester
            .widget<NavigationBar>(
              find.byType(NavigationBar),
            )
            .selectedIndex,
        4,
      );

      debugPrint('STEP 15 - Wallet tab verified');

      // Open Profile page.
      final profileFinder = find.byTooltip('Profile');

      await pumpUntilFound(
        tester,
        profileFinder,
      );

      await tester.tap(profileFinder);

      debugPrint('STEP 16 - Profile button tapped');

      await pumpUntilFound(
        tester,
        find.text('Customer name'),
      );

      expect(
        find.text('Customer name'),
        findsOneWidget,
      );

      debugPrint('STEP 17 - Profile screen loaded');

      expect(
        requests.where((path) => path == '/users/profile').length,
        1,
      );

      final themeDropdown = find.byType(
        DropdownButtonFormField<ThemeMode>,
      );

      await pumpUntilFound(
        tester,
        themeDropdown,
      );

      await tester.tap(themeDropdown);

      await pumpUi(
        tester,
        duration: const Duration(milliseconds: 300),
      );

      debugPrint('STEP 18 - Theme dropdown opened');

      await tester.tap(
        find.text('Dark').last,
      );

      await pumpUi(
        tester,
        duration: const Duration(milliseconds: 300),
      );

      expect(
        dependencies.theme.mode,
        ThemeMode.dark,
      );

      debugPrint('STEP 19 - Dark theme selected');

      await tester.pageBack();

      await pumpUi(
        tester,
        duration: const Duration(milliseconds: 500),
      );

      debugPrint('STEP 20 - Returned from profile');

      expect(
        tester
            .widget<NavigationBar>(
              find.byType(NavigationBar),
            )
            .selectedIndex,
        4,
      );

      // Return to Home.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Home'),
        ),
      );

      await pumpUi(
        tester,
        duration: const Duration(milliseconds: 500),
      );

      debugPrint('STEP 21 - Home tab tapped');

      expect(
        find.text('Keep my search'),
        findsOneWidget,
      );

      expect(
        tester.takeException(),
        isNull,
      );

      debugPrint('STEP 22 - Test completed successfully');
    },
  );
}