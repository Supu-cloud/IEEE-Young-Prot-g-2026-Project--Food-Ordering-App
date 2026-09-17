import '../../customer/domain/checkout_controller.dart';
import '../../customer/presentation/cart_wallet_screens.dart';
import '../../owner/presentation/connected_restaurant_screens.dart';
import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../customer/presentation/connected_customer_screens.dart';
import '../../customer/presentation/order_success_screen.dart';
import '../../owner/presentation/owner_screens.dart';
import '../../owner/presentation/owner_connected_screens.dart';
import '../../rider/presentation/rider_connected_screens.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late final CheckoutController _checkout;
  final _ordersRefresh = ValueNotifier(0);
  late final List<Widget> _pages;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies;
    _checkout = CheckoutController(dependencies.customerRepository);
    final profile = CustomerProfileAction(dependencies: dependencies);
    _pages = [
      CustomerHomeScreen(
        repository: dependencies.customerRepository,
        addToCart: _checkout.add,
        profileAction: profile,
      ),
      CustomerHomeScreen(
        repository: dependencies.customerRepository,
        restaurantsOnly: true,
        addToCart: _checkout.add,
        profileAction: profile,
      ),
      CustomerOrdersScreen(
        repository: dependencies.customerRepository,
        refresh: _ordersRefresh,
      ),
      CustomerCartScreen(controller: _checkout, onWallet: () => _select(4)),
      CustomerWalletScreen(
        controller: _checkout,
        onCart: () => _select(3),
        onPaid: _paymentConfirmed,
      ),
    ];
    _checkout.initialize();
  }

  void _paymentConfirmed() {
    _select(2);
    final result = _checkout.confirmation;
    final orders = (result?['orders'] as List? ?? [result])
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
    if (!mounted || orders.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          repository: widget.dependencies.customerRepository,
          orders: orders,
        ),
      ),
    );
  }

  void _select(int value) {
    setState(() => _index = value);
    if (value == 2) _ordersRefresh.value++;
    if (value == 3 && _checkout.initialized) _checkout.refreshCart();
  }

  @override
  void dispose() {
    _checkout.dispose();
    _ordersRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _checkout,
    builder: (context, _) => _RoleShell(
      dependencies: widget.dependencies,
      roleTitle: 'Customer',
      selectedIndex: _index,
      onSelected: _select,
      profileAction: CustomerProfileAction(dependencies: widget.dependencies),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Restaurants',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Badge.count(
            count: _checkout.itemCount,
            isLabelVisible: _checkout.itemCount > 0,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          selectedIcon: Badge.count(
            count: _checkout.itemCount,
            isLabelVisible: _checkout.itemCount > 0,
            child: const Icon(Icons.shopping_bag),
          ),
          label: 'Cart',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
      ],
      pages: _pages,
    ),
  );
}

class CustomerProfileAction extends StatelessWidget {
  const CustomerProfileAction({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Profile',
    icon: const Icon(Icons.person_outline),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: dependencies.session.signOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: CustomerProfileScreen(
            repository: dependencies.customerRepository,
            theme: dependencies.theme,
            language: dependencies.language,
          ),
        ),
      ),
    ),
  );
}

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => _RoleShell(
    dependencies: dependencies,
    roleTitle: 'Restaurant Owner',
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Menu',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Profile',
      ),
    ],
    pages: [
      ConnectedOwnerRestaurantScreen(
        repository: dependencies.ownerRestaurantRepository,
        dashboard: true,
        operations: dependencies.operations,
      ),
      OwnerOrdersConnected(repository: dependencies.operations),
      const OwnerMenuScreen(),
      ConnectedOwnerRestaurantScreen(
        repository: dependencies.ownerRestaurantRepository,
      ),
    ],
  );
}

class RiderShell extends StatelessWidget {
  const RiderShell({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => _RoleShell(
    dependencies: dependencies,
    roleTitle: 'Delivery Rider',
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.delivery_dining_outlined),
        selectedIcon: Icon(Icons.delivery_dining),
        label: 'Deliveries',
      ),
      NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments),
        label: 'Earnings',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
    pages: [
      RiderHomeConnected(repository: dependencies.operations),
      RiderDeliveriesConnected(repository: dependencies.operations, section: 'All'),
      RiderEarningsConnected(repository: dependencies.operations),
      RiderProfileConnected(dependencies: dependencies),
    ],
  );
}

class _RoleShell extends StatefulWidget {
  const _RoleShell({
    required this.dependencies,
    required this.roleTitle,
    required this.destinations,
    required this.pages,
    this.selectedIndex,
    this.onSelected,
    this.profileAction,
  });
  final AppDependencies dependencies;
  final String roleTitle;
  final List<NavigationDestination> destinations;
  final List<Widget> pages;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final Widget? profileAction;

  @override
  State<_RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<_RoleShell> {
  int _index = 0;

  Future<void> _signOut() async {
    await widget.dependencies.session.signOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/branding/app_logo.png',
              width: 48,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foodie',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                widget.roleTitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.profileAction != null)
          widget.profileAction!
        else
          IconButton(
            onPressed: _signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
      ],
    ),
    body: IndexedStack(
      index: widget.selectedIndex ?? _index,
      children: [
        for (var index = 0; index < widget.pages.length; index++)
          TickerMode(
            enabled: index == (widget.selectedIndex ?? _index),
            child: widget.pages[index],
          ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: widget.selectedIndex ?? _index,
      onDestinationSelected:
          widget.onSelected ?? (value) => setState(() => _index = value),
      destinations: widget.destinations,
    ),
  );
}
