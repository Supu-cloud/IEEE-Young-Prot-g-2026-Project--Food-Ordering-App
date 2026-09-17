import 'package:flutter/material.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/operations_ui.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

const _pad = EdgeInsets.fromLTRB(16, 14, 16, 110);
String _money(dynamic value) =>
    'Rs. ' + (value as num? ?? 0).round().toString();
String _label(String value) => value.replaceAll('_', ' ');

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  Widget build(BuildContext context) => FutureBuilder<AdminDashboardData>(
    future: repository.dashboard(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const AppLoading(message: 'Loading live overview...');
      if (snapshot.hasError)
        return AppError(message: snapshot.error.toString());
      final data = snapshot.data!, k = data.kpis;
      return RefreshIndicator(
        onRefresh: repository.dashboard,
        child: ListView(
          padding: _pad,
          children: [
            OperationsHeader(
              eyebrow: 'System command centre',
              title: 'Admin overview',
              subtitle: MaterialLocalizations.of(
                context,
              ).formatFullDate(DateTime.now()),
              trailing: Badge(
                label: Text((k['pendingApprovals'] ?? 0).toString()),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.payments,
                    label: 'Total sales',
                    value: _money(k['totalSales']),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.receipt_long,
                    label: 'Orders today',
                    value: (k['ordersToday'] ?? 0).toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.people,
                    label: 'Customers',
                    value: (k['totalCustomers'] ?? 0).toString(),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.store,
                    label: 'Open restaurants',
                    value: (k['openRestaurants'] ?? 0).toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.business,
                    label: 'Owners',
                    value: (k['totalRestaurantOwners'] ?? 0).toString(),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OperationsMetric(
                    icon: Icons.delivery_dining,
                    label: 'Riders',
                    value: (k['totalDeliveryRiders'] ?? 0).toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _Title('Attention required'),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.approval, color: AppColors.primaryDark),
                ),
                title: Text(
                  (k['pendingApprovals'] ?? 0).toString() +
                      ' pending applications',
                ),
                subtitle: Text(
                  (k['activeOrders'] ?? 0).toString() +
                      ' active orders · ' +
                      (k['availableRiders'] ?? 0).toString() +
                      ' available riders',
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _Title('Order status'),
            AppCard(
              child: Column(
                children: data.orderStatus
                    .map(
                      (item) => _CountRow(
                        _label(item['status'].toString()),
                        item['count'] as num? ?? 0,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            const _Title('Top restaurants'),
            AppCard(
              child: Column(
                children: data.topRestaurants
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          item['orders'].toString() + ' completed orders',
                        ),
                        trailing: Text(
                          _money(item['revenue']),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  String role = '';
  late Future<List<AdminApplication>> future = _load();
  Future<List<AdminApplication>> _load() =>
      widget.repository.applications(role: role);
  void reload() => setState(() => future = _load());
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          children: [
            const OperationsHeader(
              eyebrow: 'Partner onboarding',
              title: 'Approvals',
              subtitle: 'Verified owner and rider applications.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '', label: Text('All')),
                ButtonSegment(value: 'restaurant_owner', label: Text('Owners')),
                ButtonSegment(value: 'delivery_rider', label: Text('Riders')),
              ],
              selected: {role},
              onSelectionChanged: (value) {
                role = value.first;
                reload();
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<AdminApplication>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const AppLoading();
            if (snapshot.hasError)
              return AppError(
                message: snapshot.error.toString(),
                onRetry: reload,
              );
            final items = snapshot.data!;
            if (items.isEmpty)
              return const Center(child: Text('No pending applications.'));
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                children: items
                    .map(
                      (app) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminApplicationDetailScreen(
                                  repository: widget.repository,
                                  id: app.id,
                                ),
                              ),
                            );
                            reload();
                          },
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(app.name[0]),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        app.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _label(app.role),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    OperationsStatusChip(app.status),
                                    const SizedBox(height: 5),
                                    Text(
                                      app.emailVerified
                                          ? 'Email verified'
                                          : 'Not verified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: app.emailVerified
                                            ? AppColors.primaryDark
                                            : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class AdminApplicationDetailScreen extends StatefulWidget {
  const AdminApplicationDetailScreen({
    super.key,
    required this.repository,
    required this.id,
  });
  final AdminRepository repository;
  final String id;
  @override
  State<AdminApplicationDetailScreen> createState() =>
      _AdminApplicationDetailScreenState();
}

class _AdminApplicationDetailScreenState
    extends State<AdminApplicationDetailScreen> {
  bool busy = false;
  Future<void> _approve(AdminApplication app) async {
    if (!app.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email must be verified first.')),
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Approve application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approve'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => busy = true);
    try {
      await widget.repository.approve(app.id);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _reject(AdminApplication app) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject application'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.repository.reject(app.id, reason);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Application details')),
    body: FutureBuilder<AdminApplication>(
      future: widget.repository.application(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const AppLoading();
        if (snapshot.hasError)
          return AppError(message: snapshot.error.toString());
        final app = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  app.name[0],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                app.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Center(child: Text(_label(app.role))),
            const SizedBox(height: 15),
            AppCard(
              child: Column(
                children: [
                  _Detail('Email', app.email),
                  _Detail(
                    'Email status',
                    app.emailVerified ? 'Verified' : 'Not verified',
                  ),
                  _Detail(
                    'Phone',
                    (app.data['phone'] ?? 'Not provided').toString(),
                  ),
                  _Detail(
                    'Address',
                    (app.data['address'] ?? 'Not provided').toString(),
                  ),
                  _Detail('Status', _label(app.status)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile information',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Divider(),
                  Text(
                    app.data['profile'] == null
                        ? 'No role profile submitted.'
                        : app.data['profile'].toString(),
                  ),
                ],
              ),
            ),
            if (app.status == 'pending') ...[
              const SizedBox(height: 14),
              AppButton(
                label: 'Approve application',
                loading: busy,
                onPressed: () => _approve(app),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reject application',
                outlined: true,
                loading: busy,
                onPressed: () => _reject(app),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String range = '30d';
  @override
  Widget build(BuildContext context) => FutureBuilder<AdminAnalyticsData>(
    future: widget.repository.analytics(range: range),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const AppLoading(message: 'Loading analytics...');
      if (snapshot.hasError)
        return AppError(message: snapshot.error.toString());
      final data = snapshot.data!, sales = data.sales;
      return ListView(
        padding: _pad,
        children: [
          OperationsHeader(
            eyebrow: 'System intelligence',
            title: 'Analytics',
            subtitle: 'Backend-calculated trends.',
            trailing: DropdownButton<String>(
              value: range,
              items: const [
                DropdownMenuItem(value: '7d', child: Text('7D')),
                DropdownMenuItem(value: '30d', child: Text('30D')),
                DropdownMenuItem(value: '90d', child: Text('3M')),
                DropdownMenuItem(value: '12m', child: Text('12M')),
              ],
              onChanged: (value) => setState(() => range = value!),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OperationsMetric(
                  icon: Icons.payments,
                  label: 'Completed sales',
                  value: _money(sales['completedOrderRevenue']),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OperationsMetric(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelled value',
                  value: _money(sales['cancelledOrderValue']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Title('Sales trend'),
          AppCard(
            child: _Bars(points: data.salesTrend, keyName: 'revenue'),
          ),
          const SizedBox(height: 14),
          const _Title('User joining rate'),
          AppCard(
            child: Column(
              children: data.userGrowth
                  .take(12)
                  .map(
                    (item) => _CountRow(
                      item['date'].toString() +
                          ' · ' +
                          _label(item['role'].toString()),
                      item['count'] as num? ?? 0,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          const _Title('Order distribution'),
          AppCard(
            child: Column(
              children: data.orderStatus
                  .map(
                    (item) => _CountRow(
                      _label(item['status'].toString()),
                      item['count'] as num? ?? 0,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
    },
  );
}

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key, required this.repository, required this.language, required this.theme});
  final AdminRepository repository;
  final LanguageController language;
  final ThemeController theme;
  @override
  Widget build(BuildContext context) => ListView(
    padding: _pad,
    children: [
      const OperationsHeader(
        eyebrow: 'Administration',
        title: 'More',
        subtitle: 'Management, reports, and profile.',
      ),
      const SizedBox(height: 14),
      _More(
        Icons.people_outline,
        'Users',
        'Search and manage account status',
        () => _open(
          context,
          AdminManagementScreen(repository: repository, kind: 'users'),
        ),
      ),
      _More(
        Icons.store_outlined,
        'Restaurants',
        'Inspect operational performance',
        () => _open(
          context,
          AdminManagementScreen(repository: repository, kind: 'restaurants'),
        ),
      ),
      _More(
        Icons.receipt_long_outlined,
        'Orders',
        'Inspect system orders',
        () => _open(
          context,
          AdminManagementScreen(repository: repository, kind: 'orders'),
        ),
      ),
      _More(
        Icons.description_outlined,
        'Reports',
        'Preview backend-generated reports',
        () => _open(context, AdminReportsScreen(repository: repository)),
      ),
      _More(
        Icons.person_outline,
        'Admin profile',
        'Account and security information',
        () => _open(context, AdminProfileScreen(language: language, theme: theme)),
      ),
    ],
  );
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({
    super.key,
    required this.repository,
    required this.kind,
  });
  final AdminRepository repository;
  final String kind;
  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> future = load();
  Future<List<Map<String, dynamic>>> load() => switch (widget.kind) {
    'users' => widget.repository.users(search: search.text),
    'restaurants' => widget.repository.restaurants(search: search.text),
    _ => widget.repository.orders(search: search.text),
  };
  void reload() => setState(() => future = load());
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_label(widget.kind))),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: search,
            onSubmitted: (_) => reload(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search ' + widget.kind,
              suffixIcon: IconButton(
                onPressed: reload,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const AppLoading();
              if (snapshot.hasError)
                return AppError(
                  message: snapshot.error.toString(),
                  onRetry: reload,
                );
              final items = snapshot.data!;
              if (items.isEmpty)
                return Center(child: Text('No ' + widget.kind + ' found.'));
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                widget.kind == 'users'
                                    ? Icons.person
                                    : widget.kind == 'restaurants'
                                    ? Icons.store
                                    : Icons.receipt,
                              ),
                            ),
                            title: Text(
                              (item['name'] ?? item['_id'] ?? 'Record')
                                  .toString(),
                              maxLines: 1,
                            ),
                            subtitle: Text(_subtitle(item), maxLines: 2),
                            trailing: item['accountStatus'] != null
                                ? OperationsStatusChip(
                                    item['accountStatus'].toString(),
                                  )
                                : item['status'] != null
                                ? OperationsStatusChip(
                                    _label(item['status'].toString()),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
  String _subtitle(Map<String, dynamic> item) => widget.kind == 'users'
      ? item['email'].toString() + ' · ' + _label(item['role'].toString())
      : widget.kind == 'restaurants'
      ? (item['orderCount'] ?? 0).toString() +
            ' orders · ' +
            _money(item['revenue'])
      : _money(item['totalAmount']) + ' · ' + item['paymentStatus'].toString();
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String type = 'sales', range = '30d';
  Map<String, dynamic>? report;
  bool busy = false;
  Future<void> generate() async {
    setState(() => busy = true);
    try {
      report = await widget.repository.report(type, range: range);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Report'),
          items:
              [
                    'sales',
                    'orders',
                    'customers',
                    'users',
                    'restaurants',
                    'riders',
                    'approvals',
                  ]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_label(value)),
                    ),
                  )
                  .toList(),
          onChanged: (value) => setState(() => type = value!),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: range,
          decoration: const InputDecoration(labelText: 'Period'),
          items: const [
            DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
            DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
            DropdownMenuItem(value: '90d', child: Text('3 months')),
            DropdownMenuItem(value: '12m', child: Text('12 months')),
          ],
          onChanged: (value) => setState(() => range = value!),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Generate preview',
          loading: busy,
          onPressed: generate,
        ),
        if (report != null) ...[
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report!['title'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(),
                Text(
                  ((report!['summary'] as Map?)?['records'] ?? 0).toString() +
                      ' records',
                ),
                const SizedBox(height: 8),
                Text(
                  'CSV export is available from the website admin portal.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key, required this.language, required this.theme});
  final LanguageController language;
  final ThemeController theme;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin profile')),
    body: Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.admin_panel_settings, size: 38),
            ),
            SizedBox(height: 10),
            Text(
              'System Administrator',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('Protected by the current verified session.'),
            SizedBox(height: 18),
            LanguageSelector(controller: language),
            SizedBox(height: 12),
            ThemeSelector(controller: theme),
          ],
        ),
      ),
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.points, required this.keyName});
  final List<Map<String, dynamic>> points;
  final String keyName;
  @override
  Widget build(BuildContext context) {
    final max = points.fold<num>(1, (value, item) {
      final current = item[keyName] as num? ?? 0;
      return current > value ? current : value;
    });
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((item) {
          final value = item[keyName] as num? ?? 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: 10 + 150 * value / max,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.value);
  final String label;
  final num value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _More extends StatelessWidget {
  const _More(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}
