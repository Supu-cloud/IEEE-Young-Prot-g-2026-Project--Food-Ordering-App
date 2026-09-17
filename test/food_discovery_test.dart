import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/features/customer/data/customer_repository.dart';
import 'package:food_ordering_app/features/customer/presentation/connected_customer_screens.dart';

RestaurantData restaurant(String id, {bool open = true}) => RestaurantData(
  id: id,
  name: 'Kitchen $id',
  description: '',
  address: 'Colombo',
  category: 'Sri Lankan',
  isOpen: open,
);

MenuItemData food(
  String id,
  String name,
  String category, {
  bool available = true,
}) => MenuItemData(
  id: id,
  name: name,
  description: 'Freshly prepared',
  price: 850,
  category: category,
  restaurantId: id,
  available: available,
);

class DiscoveryRepository extends CustomerRepository {
  DiscoveryRepository({this.failSecondMenu = false}) : super(Dio());
  final bool failSecondMenu;
  final added = <String>[];

  @override
  Future<List<RestaurantData>> getRestaurants() async => [
    restaurant('a'),
    restaurant('b', open: false),
  ];

  @override
  Future<List<MenuItemData>> getMenu(String restaurantId) async {
    if (restaurantId == 'b' && failSecondMenu) {
      throw Exception('Menu unavailable');
    }
    return restaurantId == 'a'
        ? [
            food('a', 'Chicken kottu', 'Kottu'),
            food('hidden', 'Sold out', 'Rice', available: false),
          ]
        : [food('b', 'Rice and curry', 'Rice')];
  }

  @override
  Future<CartData> addToCart(String menuItemId, {int quantity = 1}) async {
    added.add(menuItemId);
    return const CartData(items: [], totalAmount: 850);
  }
}

void main() {
  test(
    'food feed keeps restaurant ownership, availability and open-first order',
    () async {
      final result = await DiscoveryRepository().getFoodDiscovery();
      expect(result.foods.map((food) => food.item.name), [
        'Chicken kottu',
        'Rice and curry',
      ]);
      expect(result.foods.first.restaurant.id, 'a');
      expect(result.foods.last.restaurant.isOpen, isFalse);
      expect(result.failedMenus, 0);
    },
  );

  test(
    'one failed menu preserves other restaurants food and reports partial failure',
    () async {
      final result = await DiscoveryRepository(
        failSecondMenu: true,
      ).getFoodDiscovery();
      expect(result.foods.single.item.name, 'Chicken kottu');
      expect(result.failedMenus, 1);
    },
  );

  testWidgets('home shows feast and food, adds food, and filters categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DiscoveryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomerHomeScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sri Lankan feast'), findsOneWidget);
    expect(find.text('Chicken kottu'), findsOneWidget);
    expect(find.text('Restaurants near you'), findsNothing);
    await tester.tap(find.byTooltip('Add Chicken kottu to cart'));
    await tester.pumpAndSettle();
    expect(repository.added, ['a']);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rice'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken kottu'), findsNothing);
    expect(find.text('Rice and curry'), findsOneWidget);
    final closedAdd = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == 'Add Rice and curry to cart',
      ),
    );
    expect(closedAdd.onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'not on the menu');
    await tester.pumpAndSettle();
    expect(find.text('No food items found.'), findsOneWidget);
  });

  testWidgets('restaurant section opens the selected restaurant menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerHomeScreen(
            repository: DiscoveryRepository(),
            restaurantsOnly: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Restaurants near you'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kitchen b'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Kitchen b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen b'));
    await tester.pumpAndSettle();
    expect(find.text('Rice and curry'), findsOneWidget);
    expect(find.text('Chicken kottu'), findsNothing);
  });
}
