import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';

class OperationsDashboard extends StatelessWidget {
  const OperationsDashboard({super.key, required this.owner});
  final bool owner;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              owner ? Icons.storefront : Icons.delivery_dining,
              color: AppColors.primary,
              size: 38,
            ),
            const SizedBox(height: 24),
            Text(
              owner ? 'Good evening, partner' : 'Ayubowan, ready to ride?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              owner
                  ? 'Your Colombo kitchen is open and receiving orders.'
                  : 'Go online to receive nearby delivery requests.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: _Metric(
              label: owner ? 'Today’s orders' : 'Completed',
              value: owner ? '18' : '7',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Metric(
              label: owner ? 'Sales' : 'Earnings',
              value: owner ? 'Rs. 42K' : 'Rs. 3.8K',
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      AppCard(
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(
                Icons.campaign_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                owner
                    ? '3 orders need your attention'
                    : 'High demand around Nugegoda right now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ],
  );
}

class OperationsListScreen extends StatefulWidget {
  const OperationsListScreen({
    super.key,
    required this.owner,
    required this.kind,
  });
  final bool owner;
  final String kind;
  @override
  State<OperationsListScreen> createState() => _OperationsListScreenState();
}

class _OperationsListScreenState extends State<OperationsListScreen> {
  bool _enabled = true;
  @override
  Widget build(BuildContext context) {
    if (widget.kind == 'profile') {
      return _ProfileSettings(owner: widget.owner);
    }
    if (widget.kind == 'earnings') {
      return _Earnings(owner: widget.owner);
    }
    if (widget.kind == 'menu') {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(
                'Menu items',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton.filled(
                onPressed: () => _notice('Add menu item'),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ToggleItem(
            name: 'Cheese Chicken Kottu',
            price: 'Rs. 1,450',
            image: 'assets/images/cheese_kottu.png',
          ),
          _ToggleItem(
            name: 'Egg Hopper Breakfast',
            price: 'Rs. 980',
            image: 'assets/images/egg_hoppers.png',
          ),
        ],
      );
    }
    if (widget.kind == 'restaurant') {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  'assets/images/sri_lankan_feast_v2.png',
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 230,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xA6262422)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Authentic Sri Lankan Kitchen',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Ceylon Kitchen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text('Authentic Sri Lankan comfort food • Colombo'),
          const SizedBox(height: 18),
          SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: Text(
              _enabled
                  ? 'Restaurant is accepting orders'
                  : 'Restaurant is closed',
            ),
            secondary: const Icon(Icons.storefront),
          ),
          AppButton(
            label: 'Edit restaurant details',
            outlined: true,
            onPressed: () => _notice('Edit restaurant'),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.owner ? 'Incoming orders' : 'Delivery assignments',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.owner ? 'Order #FD1042' : 'Delivery #DL208',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const StatusChip(status: AppStatus.preparing),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.owner
                    ? '2 × Cheese Chicken Kottu\n1 × Ceylon milk tea'
                    : 'Kottu Kadé → Kottawa\n3.4 km • Cash order',
              ),
              const SizedBox(height: 14),
              AppButton(
                label: widget.owner
                    ? 'Accept & start preparing'
                    : 'Accept delivery',
                onPressed: () => _notice(
                  widget.owner ? 'Order accepted' : 'Delivery accepted',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _ToggleItem extends StatefulWidget {
  const _ToggleItem({
    required this.name,
    required this.price,
    required this.image,
  });
  final String name, price, image;
  @override
  State<_ToggleItem> createState() => _ToggleItemState();
}

class _ToggleItemState extends State<_ToggleItem> {
  bool enabled = true;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              widget.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(widget.price),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => setState(() => enabled = value),
          ),
        ],
      ),
    ),
  );
}

class _Earnings extends StatelessWidget {
  const _Earnings({required this.owner});
  final bool owner;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        owner ? 'Sales overview' : 'Your earnings',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              owner ? 'This week' : 'Available to withdraw',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              owner ? 'Rs. 184,600' : 'Rs. 8,750',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const AppCard(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Today'),
              trailing: Text('Rs. 3,850'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('This week'),
              trailing: Text('Rs. 18,400'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileSettings extends StatelessWidget {
  const _ProfileSettings({required this.owner});
  final bool owner;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const CircleAvatar(
        radius: 42,
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.person, size: 44, color: AppColors.primaryDark),
      ),
      const SizedBox(height: 12),
      Text(
        owner ? 'Restaurant partner' : 'Delivery partner',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 24),
      const AppCard(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Personal information'),
              trailing: Icon(Icons.chevron_right),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Account verification'),
              trailing: Icon(Icons.chevron_right),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help & support'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ],
  );
}
