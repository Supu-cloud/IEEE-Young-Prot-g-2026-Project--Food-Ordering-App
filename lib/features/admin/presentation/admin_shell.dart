import 'package:flutter/material.dart';
import '../../../core/di/app_dependencies.dart';
import 'admin_screens.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final repository = widget.dependencies.adminRepository;
    final pages = [
      AdminDashboardScreen(repository: repository),
      AdminApprovalsScreen(repository: repository),
      AdminAnalyticsScreen(repository: repository),
      AdminMoreScreen(repository: repository, language: widget.dependencies.language, theme: widget.dependencies.theme),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset('assets/branding/app_logo.png', width: 48, height: 40, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foodie', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Administration', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await widget.dependencies.session.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
