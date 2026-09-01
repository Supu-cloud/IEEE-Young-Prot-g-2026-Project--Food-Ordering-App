import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../customer/presentation/customer_screens.dart';
import 'operations_screens.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => _RoleShell(
    dependencies: dependencies,
    roleTitle: 'Customer',
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Wallet',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
    pages: const [
      CustomerHomeScreen(),
      CustomerOrdersScreen(),
      CustomerWalletScreen(),
      CustomerProfileScreen(),
    ],
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
        label: 'Restaurant',
      ),
    ],
    pages: const [
      OperationsDashboard(owner: true),
      OperationsListScreen(owner: true, kind: 'orders'),
      OperationsListScreen(owner: true, kind: 'menu'),
      OperationsListScreen(owner: true, kind: 'restaurant'),
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
    pages: const [
      OperationsDashboard(owner: false),
      OperationsListScreen(owner: false, kind: 'orders'),
      OperationsListScreen(owner: false, kind: 'earnings'),
      OperationsListScreen(owner: false, kind: 'profile'),
    ],
  );
}

class _RoleShell extends StatefulWidget {
  const _RoleShell({
    required this.dependencies,
    required this.roleTitle,
    required this.destinations,
    required this.pages,
  });
  final AppDependencies dependencies;
  final String roleTitle;
  final List<NavigationDestination> destinations;
  final List<Widget> pages;

  @override
  State<_RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<_RoleShell> {
  int _index = 0;

  Future<void> _signOut() async {
    await widget.dependencies.session.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foodie', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(widget.roleTitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _signOut,
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: IndexedStack(index: _index, children: widget.pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: widget.destinations,
    ),
  );
}
