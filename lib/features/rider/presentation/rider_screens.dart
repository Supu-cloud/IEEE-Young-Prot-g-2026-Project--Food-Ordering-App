import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/operations_ui.dart';
import '../data/rider_mock_data.dart';

const _padding = EdgeInsets.fromLTRB(16, 14, 16, 110);
const _flow = [
  'Assigned',
  'Accepted',
  'Picked Up',
  'Out for Delivery',
  'Delivered',
];

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});
  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  bool online = true;
  @override
  Widget build(BuildContext context) {
    final active = riderDeliveriesMock[1];
    return ListView(
      padding: _padding,
      children: [
        OperationsHeader(
          eyebrow: 'Rider workspace',
          title: 'Ayubowan, Kasun',
          subtitle: online ? 'Online · Receiving requests' : 'Offline',
          trailing: Switch(
            value: online,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => online = v),
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: OperationsMetric(
                icon: Icons.payments_outlined,
                label: "Today's earnings",
                value: 'Rs. 3,850',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: OperationsMetric(
                icon: Icons.delivery_dining,
                label: 'Completed today',
                value: '7',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Title('Current delivery'),
        _DeliveryCard(active),
        const SizedBox(height: 20),
        const _Title('Delivery requests'),
        ...riderDeliveriesMock
            .where((d) => d.status == 'Assigned')
            .map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _DeliveryCard(d),
              ),
            ),
      ],
    );
  }
}

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});
  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  String tab = 'Assigned';
  @override
  Widget build(BuildContext context) {
    final items = riderDeliveriesMock.where(
      (d) => tab == 'Assigned'
          ? d.status == 'Assigned'
          : tab == 'Completed'
          ? d.status == 'Delivered'
          : !['Assigned', 'Delivered'].contains(d.status),
    );
    return ListView(
      padding: _padding,
      children: [
        const OperationsHeader(
          eyebrow: 'Delivery queue',
          title: 'Deliveries',
          subtitle: 'Review pickup, route, and destination.',
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Assigned', label: Text('Assigned')),
            ButtonSegment(value: 'Active', label: Text('Active')),
            ButtonSegment(value: 'Completed', label: Text('Completed')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const AppCard(
            child: Center(child: Text('No deliveries in this group.')),
          ),
        ...items.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _DeliveryCard(d),
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard(this.delivery);
  final RiderDeliveryMock delivery;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderDeliveryDetailScreen(delivery: delivery),
      ),
    ),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${delivery.id}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              OperationsStatusChip(delivery.status),
            ],
          ),
          const SizedBox(height: 12),
          _Place(Icons.storefront, delivery.restaurant, delivery.pickup),
          const Padding(
            padding: EdgeInsets.only(left: 17),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(color: AppColors.border),
            ),
          ),
          _Place(Icons.location_on, delivery.customer, delivery.dropoff),
          const Divider(),
          Row(
            children: [
              Text(
                '${delivery.distance} · ${delivery.eta}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'Rs. ${delivery.earning}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ],
      ),
    ),
  );
}

class RiderDeliveryDetailScreen extends StatefulWidget {
  const RiderDeliveryDetailScreen({super.key, required this.delivery});
  final RiderDeliveryMock delivery;
  @override
  State<RiderDeliveryDetailScreen> createState() =>
      _RiderDeliveryDetailScreenState();
}

class _RiderDeliveryDetailScreenState extends State<RiderDeliveryDetailScreen> {
  late String status = widget.delivery.status;
  @override
  Widget build(BuildContext context) {
    final index = _flow.indexOf(status);
    final next = index < _flow.length - 1 ? _flow[index + 1] : null;
    return Scaffold(
      appBar: AppBar(title: Text('Delivery ${widget.delivery.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MockMapPanel(),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _Place(
                  Icons.storefront,
                  widget.delivery.restaurant,
                  widget.delivery.pickup,
                  contact: true,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 17),
                  child: SizedBox(
                    height: 22,
                    child: VerticalDivider(color: AppColors.border),
                  ),
                ),
                _Place(
                  Icons.location_on,
                  widget.delivery.customer,
                  widget.delivery.dropoff,
                  contact: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Divider(),
                Text('2 × Cheese Chicken Kottu'),
                SizedBox(height: 5),
                Text('1 × Ceylon Milk Tea'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Title('Delivery progress'),
          ..._flow.asMap().entries.map(
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
              trailing: e.key == index ? OperationsStatusChip(status) : null,
            ),
          ),
          if (next != null)
            AppButton(
              label: status == 'Assigned'
                  ? 'Accept delivery'
                  : status == 'Accepted'
                  ? 'Confirm pickup'
                  : status == 'Picked Up'
                  ? 'Start delivery'
                  : 'Mark delivered',
              icon: Icons.delivery_dining,
              onPressed: () => setState(() => status = next),
            ),
        ],
      ),
    );
  }
}

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: _padding,
    children: [
      const OperationsHeader(
        eyebrow: 'Rider performance',
        title: 'Earnings',
        subtitle: 'Mock income and delivery summary.',
      ),
      const SizedBox(height: 16),
      const Row(
        children: [
          Expanded(
            child: OperationsMetric(
              icon: Icons.today,
              label: 'Today',
              value: 'Rs. 3,850',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OperationsMetric(
              icon: Icons.calendar_view_week,
              label: 'This week',
              value: 'Rs. 21.4k',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Row(
        children: [
          Expanded(
            child: OperationsMetric(
              icon: Icons.delivery_dining,
              label: 'Completed',
              value: '38',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OperationsMetric(
              icon: Icons.payments,
              label: 'Average',
              value: 'Rs. 550',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly earnings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 18),
            _EarningsBars(),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent earnings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Divider(),
            _Earning('Today · 7 trips', 'Rs. 3,850'),
            _Earning('Yesterday · 6 trips', 'Rs. 3,240'),
            _Earning('Wednesday · 8 trips', 'Rs. 4,180'),
          ],
        ),
      ),
    ],
  );
}

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});
  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  bool available = true, editing = false;
  @override
  Widget build(BuildContext context) => ListView(
    padding: _padding,
    children: [
      OperationsHeader(
        eyebrow: 'Account & settings',
        title: 'Rider profile',
        subtitle: 'Manage your details and availability.',
        trailing: IconButton(
          onPressed: () => setState(() => editing = !editing),
          icon: Icon(editing ? Icons.close : Icons.edit_outlined),
        ),
      ),
      const SizedBox(height: 14),
      const Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, size: 48, color: AppColors.primaryDark),
        ),
      ),
      const SizedBox(height: 9),
      const Center(
        child: Text(
          'Kasun Perera',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(
            child: OperationsMetric(
              icon: Icons.star,
              label: 'Rating',
              value: '4.9',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OperationsMetric(
              icon: Icons.delivery_dining,
              label: 'Completed',
              value: '384',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AppCard(
        child: Column(
          children: [
            TextFormField(
              initialValue: '077 456 1290',
              enabled: editing,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: 'Motorcycle',
              enabled: editing,
              decoration: const InputDecoration(labelText: 'Vehicle type'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: 'WP BCT-4821',
              enabled: editing,
              decoration: const InputDecoration(labelText: 'Vehicle number'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for deliveries'),
              value: available,
              activeTrackColor: AppColors.primary,
              onChanged: editing ? (v) => setState(() => available = v) : null,
            ),
          ],
        ),
      ),
      if (editing)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppButton(
            label: 'Save profile',
            onPressed: () => setState(() => editing = false),
          ),
        ),
    ],
  );
}

class _Place extends StatelessWidget {
  const _Place(this.icon, this.title, this.subtitle, {this.contact = false});
  final IconData icon;
  final String title, subtitle;
  final bool contact;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.primaryLight,
        child: Icon(icon, size: 18, color: AppColors.primaryDark),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      if (contact) ...[
        IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.message_outlined)),
      ],
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _Earning extends StatelessWidget {
  const _Earning(this.label, this.amount);
  final String label, amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _EarningsBars extends StatelessWidget {
  const _EarningsBars();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 170,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [38, 55, 44, 68, 61, 88, 74]
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
