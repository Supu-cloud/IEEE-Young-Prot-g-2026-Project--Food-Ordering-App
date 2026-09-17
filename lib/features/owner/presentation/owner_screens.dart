import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/operations_ui.dart';
import '../data/owner_mock_data.dart';

const _padding = EdgeInsets.fromLTRB(16, 14, 16, 110);

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});
  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool open = true;
  @override
  Widget build(BuildContext context) => ListView(
    padding: _padding,
    children: [
      OperationsHeader(
        eyebrow: 'Restaurant workspace',
        title: 'Good morning',
        subtitle: 'Ceylon Kitchen',
        trailing: Switch(
          value: open,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => setState(() => open = v),
        ),
      ),
      Text(
        open ? 'Open · Accepting orders' : 'Closed · Orders paused',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(
            child: OperationsMetric(
              icon: Icons.receipt_long,
              label: "Today's orders",
              value: '24',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OperationsMetric(
              icon: Icons.payments_outlined,
              label: 'Revenue',
              value: 'Rs. 18.4k',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Row(
        children: [
          Expanded(
            child: OperationsMetric(
              icon: Icons.schedule,
              label: 'Pending',
              value: '4',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OperationsMetric(
              icon: Icons.soup_kitchen_outlined,
              label: 'Preparing',
              value: '6',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const _SectionTitle('Recent orders'),
      ...ownerOrdersMock
          .take(3)
          .map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _OrderCard(o),
            ),
          ),
      const SizedBox(height: 14),
      const _SectionTitle('Quick actions'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Action(Icons.receipt_long, 'View orders', () {}),
          _Action(
            Icons.add_circle_outline,
            'Add menu item',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerMenuEditorScreen()),
            ),
          ),
          _Action(
            Icons.storefront,
            'Restaurant',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RestaurantEditScreen()),
            ),
          ),
          _Action(
            Icons.bar_chart,
            'Analytics',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerAnalyticsScreen()),
            ),
          ),
        ],
      ),
    ],
  );
}

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});
  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  String status = 'Pending';
  static const statuses = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];
  @override
  Widget build(BuildContext context) {
    final orders = ownerOrdersMock.where((o) => o.status == status);
    return ListView(
      padding: _padding,
      children: [
        const OperationsHeader(
          eyebrow: 'Order management',
          title: 'Orders',
          subtitle: 'Keep every customer order moving.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: statuses
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: s == status,
                      onSelected: (_) => setState(() => status = s),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No orders in this status.'),
              ),
            ),
          ),
        ...orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _OrderCard(o),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);
  final OwnerOrderMock order;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OwnerOrderDetailScreen(order: order)),
    ),
    child: AppCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.receipt_long, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id} · ${order.customer}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${order.items} items · ${order.time}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Rs. ${order.total}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          OperationsStatusChip(order.status),
        ],
      ),
    ),
  );
}

class OwnerOrderDetailScreen extends StatefulWidget {
  const OwnerOrderDetailScreen({super.key, required this.order});
  final OwnerOrderMock order;
  @override
  State<OwnerOrderDetailScreen> createState() => _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends State<OwnerOrderDetailScreen> {
  late String status = widget.order.status;
  static const flow = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];
  @override
  Widget build(BuildContext context) {
    final index = flow.indexOf(status);
    return Scaffold(
      appBar: AppBar(title: Text('Order ${widget.order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.customer,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              OperationsStatusChip(status),
            ],
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordered items',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Divider(),
                _Line('2 × Cheese Chicken Kottu', 'Rs. 2,900'),
                _Line('1 × Ceylon Milk Tea', 'Rs. 380'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer & delivery',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text('Maya Perera · 077 234 6789'),
                Text(
                  '18 Flower Road, Colombo 07',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                _Line('Subtotal', 'Rs. ${widget.order.total}'),
                const _Line('Delivery', 'Rs. 250'),
                const Divider(),
                _Line('Total', 'Rs. ${widget.order.total + 250}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Order progress'),
          ...flow.asMap().entries.map(
            (e) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: e.key <= index
                    ? AppColors.primary
                    : AppColors.border,
                child: e.key < index
                    ? const Icon(Icons.check, size: 15)
                    : Text(
                        '${e.key + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
              ),
              title: Text(e.value),
            ),
          ),
          if (index >= 0 && index < flow.length - 1)
            AppButton(
              label: index == 0
                  ? 'Confirm order'
                  : index == 1
                  ? 'Start preparing'
                  : index == 2
                  ? 'Mark out for delivery'
                  : 'Mark delivered',
              onPressed: () => setState(() => status = flow[index + 1]),
            ),
          if (status != 'Delivered')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppButton(
                label: 'Cancel order',
                outlined: true,
                onPressed: () => setState(() => status = 'Cancelled'),
              ),
            ),
        ],
      ),
    );
  }
}

class OwnerMenuScreen extends StatefulWidget {
  const OwnerMenuScreen({super.key});
  @override
  State<OwnerMenuScreen> createState() => _OwnerMenuScreenState();
}

class _OwnerMenuScreenState extends State<OwnerMenuScreen> {
  String query = '', category = 'All';
  late final available = {
    for (final item in ownerMenuMock) item.name: item.available,
  };
  @override
  Widget build(BuildContext context) {
    final items = ownerMenuMock.where(
      (i) =>
          (category == 'All' || i.category == category) &&
          i.name.toLowerCase().contains(query.toLowerCase()),
    );
    return Scaffold(
      body: ListView(
        padding: _padding,
        children: [
          const OperationsHeader(
            eyebrow: 'Restaurant catalogue',
            title: 'Menu',
            subtitle: 'Manage items and availability.',
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search menu items',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Kottu', 'Breakfast', 'Rice', 'Dessert']
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: category == s,
                        onSelected: (_) => setState(() => category = s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Rs. ${item.price}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: available[item.name]!,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => available[item.name] = v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerMenuEditorScreen(item: item),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OwnerMenuEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class OwnerMenuEditorScreen extends StatefulWidget {
  const OwnerMenuEditorScreen({super.key, this.item});
  final OwnerMenuMock? item;
  @override
  State<OwnerMenuEditorScreen> createState() => _OwnerMenuEditorScreenState();
}

class _OwnerMenuEditorScreenState extends State<OwnerMenuEditorScreen> {
  late bool available;
  @override
  void initState() {
    super.initState();
    available = widget.item?.available ?? true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Add menu item' : 'Edit menu item'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40),
              Text('Image placeholder'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: widget.item?.name,
          decoration: const InputDecoration(labelText: 'Item name'),
        ),
        const SizedBox(height: 10),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: widget.item?.category,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: widget.item?.price.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price'),
        ),
        const SizedBox(height: 10),
        const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Preparation time (minutes)'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available'),
          value: available,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => setState(() => available = v),
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Save item', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});
  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  bool open = true;
  @override
  Widget build(BuildContext context) => ListView(
    padding: _padding,
    children: [
      const OperationsHeader(
        eyebrow: 'Restaurant profile',
        title: 'Ceylon Kitchen',
        subtitle: 'Sri Lankan cuisine',
      ),
      const SizedBox(height: 12),
      Container(
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.storefront,
          size: 62,
          color: AppColors.primaryDark,
        ),
      ),
      const SizedBox(height: 10),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Authentic Sri Lankan comfort food prepared with local ingredients.',
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on_outlined),
              title: Text('128 Galle Road, Colombo 03'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_outlined),
              title: Text('011 245 8890'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      AppCard(
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restaurant open'),
              subtitle: const Text('Accepting new orders'),
              value: open,
              activeTrackColor: AppColors.primary,
              onChanged: (v) => setState(() => open = v),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule),
              title: Text('Operating hours'),
              subtitle: Text('Mon–Fri 8 AM–10 PM\\nSat–Sun 9 AM–9 PM'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      AppButton(
        label: 'Edit restaurant',
        icon: Icons.edit_outlined,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantEditScreen()),
        ),
      ),
      const SizedBox(height: 8),
      AppButton(
        label: 'View analytics',
        outlined: true,
        icon: Icons.bar_chart,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OwnerAnalyticsScreen()),
        ),
      ),
    ],
  );
}

class RestaurantEditScreen extends StatelessWidget {
  const RestaurantEditScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit restaurant')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Restaurant name'),
        ),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Category')),
        const SizedBox(height: 10),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Address')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 16),
        AppButton(
          label: 'Save locally',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class OwnerAnalyticsScreen extends StatelessWidget {
  const OwnerAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analytics')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Expanded(
              child: OperationsMetric(
                icon: Icons.today,
                label: 'Today',
                value: 'Rs. 18.4k',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: OperationsMetric(
                icon: Icons.calendar_view_week,
                label: 'This week',
                value: 'Rs. 96.2k',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: OperationsMetric(
                icon: Icons.calendar_month,
                label: 'This month',
                value: 'Rs. 384k',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: OperationsMetric(
                icon: Icons.receipt,
                label: 'Avg. order',
                value: 'Rs. 1,840',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue trend',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 18),
              _MockBars(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular items',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              _Line('Cheese Chicken Kottu', '42 orders'),
              _Line('Chicken Lamprais', '36 orders'),
              _Line('Egg Hopper Breakfast', '29 orders'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _MockBars extends StatelessWidget {
  const _MockBars();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 170,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [35, 52, 45, 70, 63, 88, 76]
          .map(
            (height) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: height * 1.6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        alignment: Alignment.centerLeft,
      ),
    ),
  );
}
