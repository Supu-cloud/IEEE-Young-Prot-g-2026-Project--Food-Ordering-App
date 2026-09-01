import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _query = '';
  String _category = 'All';
  final _items = const [
    _Food(
      'Cheese Chicken Kottu',
      'Kottu Kadé',
      1450,
      4.8,
      'Kottu',
      'assets/images/cheese_kottu.png',
    ),
    _Food(
      'Egg Hopper Breakfast',
      'Hela Bojun',
      980,
      4.7,
      'Breakfast',
      'assets/images/egg_hoppers.png',
    ),
    _Food(
      'Sri Lankan Family Feast',
      'Ceylon Kitchen',
      3850,
      4.9,
      'Rice & Curry',
      'assets/images/sri_lankan_feast_v2.png',
    ),
    _Food(
      'Ulundu Vadai',
      'Jaffna Flavours',
      320,
      4.7,
      'Short Eats',
      'assets/images/vadai.png',
    ),
    _Food(
      'Pittu & Chicken Curry',
      'Ceylon Kitchen',
      1150,
      4.8,
      'Breakfast',
      'assets/images/pittu.png',
    ),
    _Food(
      'Kiribath Breakfast',
      'Ape Gedara',
      680,
      4.8,
      'Breakfast',
      'assets/images/kiribath.png',
    ),
    _Food(
      'Konda Kawum',
      'Avurudu Gedara',
      480,
      4.8,
      'Sweets',
      'assets/images/kavum.png',
    ),
    _Food(
      'Kokis',
      'Avurudu Gedara',
      420,
      4.9,
      'Sweets',
      'assets/images/kokis.png',
    ),
    _Food(
      'Pani Walalu',
      'Kandy Sweet House',
      650,
      4.9,
      'Sweets',
      'assets/images/pani_walalu.png',
    ),
    _Food(
      'Boondi',
      'Jaffna Sweet Corner',
      450,
      4.6,
      'Sweets',
      'assets/images/boondi.png',
    ),
    _Food(
      'Puhul Dosi',
      'Galle Heritage Sweets',
      560,
      4.7,
      'Sweets',
      'assets/images/puhul_dosi.png',
    ),
    _Food(
      'Mung Kavum',
      'Avurudu Gedara',
      520,
      4.8,
      'Sweets',
      'assets/images/mung_kavum.png',
    ),
    _Food(
      'Mun Guli',
      'Matale Sweet Kitchen',
      460,
      4.7,
      'Sweets',
      'assets/images/mun_guli.png',
    ),
    _Food(
      'Laveria',
      'Ape Gedara',
      390,
      4.8,
      'Sweets',
      'assets/images/lavariya.png',
    ),
    _Food(
      'Coconut Pancake',
      'Ceylon Tea Room',
      450,
      4.7,
      'Sweets',
      'assets/images/pancake.png',
    ),
    _Food(
      'Aasmi',
      'Avurudu Gedara',
      580,
      4.8,
      'Sweets',
      'assets/images/asmi.png',
    ),
    _Food(
      'Handi Kawum',
      'Matara Sweet House',
      500,
      4.7,
      'Sweets',
      'assets/images/handi_kawum.png',
    ),
    _Food(
      'Gotu Pittu',
      'Ruhunu Sweet House',
      540,
      4.8,
      'Sweets',
      'assets/images/gotu_pittu.png',
    ),
    _Food(
      'Sau Dodol',
      'Hambantota Dodol House',
      780,
      4.9,
      'Sweets',
      'assets/images/sau_dodol.png',
    ),
    _Food(
      'Pani Aluwa',
      'Kandy Sweet House',
      480,
      4.7,
      'Sweets',
      'assets/images/pani_aluwa.png',
    ),
    _Food(
      'Kiri Toffee',
      'Colombo Milk Toffee',
      620,
      4.8,
      'Sweets',
      'assets/images/kiri_toffee.png',
    ),
    _Food(
      'Aggala',
      'Ceylon Tea Room',
      420,
      4.8,
      'Sweets',
      'assets/images/aggala.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) {
      final categoryMatch = _category == 'All' || item.category == _category;
      return categoryMatch &&
          '${item.name} ${item.restaurant}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.location_on, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Text(
                    'Kottawa, Colombo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showCart(context),
              icon: Badge(
                label: ValueListenableBuilder<int>(
                  valueListenable: _DemoCart.count,
                  builder: (_, value, child) => Text('$value'),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search kottu, hoppers, restaurants...',
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.asset(
                'assets/images/sri_lankan_feast_v2.png',
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 210,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD9262422)],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A taste of home',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Sri Lankan favourites\ndelivered warm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _SweetShopScreen(
                items: _items
                    .where((item) => item.category == 'Sweets')
                    .toList(),
                onItemTap: (item) => _showFood(context, item),
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7A3528), Color(0xFFB86B3E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFE7B5),
                  child: Icon(Icons.bakery_dining, color: Color(0xFF7A3528)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sri Lankan Sweet Shop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Kavum, kokis, dodol and more',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'What are you craving?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                [
                      'All',
                      'Breakfast',
                      'Kottu',
                      'Rice & Curry',
                      'Short Eats',
                      'Sweets',
                    ]
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              'Popular near you',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        ...visible.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FoodCard(item: item, onTap: () => _showFood(context, item)),
          ),
        ),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No dishes found. Try another search.')),
          ),
      ],
    );
  }

  void _showFood(
    BuildContext context,
    _Food item,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewPaddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              item.image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 18),
          Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('${item.restaurant}  •  25–35 min  •  ★ ${item.rating}'),
          const SizedBox(height: 12),
          Text(
            'Freshly prepared with local spices and ingredients. Add a note after placing it in your cart.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Add to cart  •  Rs. ${item.price}',
            onPressed: () {
              _DemoCart.add(item);
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('${item.name} added to cart')),
              );
            },
          ),
        ],
      ),
    ),
  );

  void _showCart(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ValueListenableBuilder<List<_Food>>(
      valueListenable: _DemoCart.items,
      builder: (context, items, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewPaddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your cart', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Your cart is empty')),
              ),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.image,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(item.name),
                subtitle: Text('Rs. ${item.price}'),
                trailing: IconButton(
                  onPressed: () => _DemoCart.remove(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
            if (items.isNotEmpty) ...[
              const Divider(),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'Rs. ${items.fold<int>(0, (sum, item) => sum + item.price)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Proceed to checkout',
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Checkout is ready to connect to the order API.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
          Tab(text: 'Cancelled'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _OrderList(
              children: const [
                _OrderTile(
                  name: 'Cheese Chicken Kottu',
                  restaurant: 'Kottu Kadé',
                  price: 1450,
                  status: AppStatus.preparing,
                  image: 'assets/images/cheese_kottu.png',
                ),
              ],
            ),
            _OrderList(
              children: const [
                _OrderTile(
                  name: 'Egg Hopper Breakfast',
                  restaurant: 'Hela Bojun',
                  price: 980,
                  status: AppStatus.delivered,
                  image: 'assets/images/egg_hoppers.png',
                ),
              ],
            ),
            const Center(child: Text('No cancelled orders')),
          ],
        ),
      ),
    ],
  );
}

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});
  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  String _method = 'Cash on delivery';
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foodie Wallet', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 14),
            Text(
              'Rs. 2,450.00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text('Available balance', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text('Payment methods', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      ...[
        ('Cash on delivery', Icons.payments_outlined),
        ('Visa •••• 4321', Icons.credit_card),
        ('Foodie Wallet', Icons.account_balance_wallet_outlined),
      ].map(
        (entry) => ListTile(
          onTap: () => setState(() => _method = entry.$1),
          leading: Icon(entry.$2),
          title: Text(entry.$1),
          trailing: Icon(
            _method == entry.$1 ? Icons.check_circle : Icons.circle_outlined,
            color: _method == entry.$1
                ? AppColors.primaryDark
                : AppColors.placeholder,
          ),
        ),
      ),
      const SizedBox(height: 16),
      AppButton(
        label: 'Add payment method',
        outlined: true,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment setup will open here.')),
        ),
      ),
    ],
  );
}

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, size: 34, color: AppColors.primaryDark),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayubowan!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text('Your Foodie account'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          children: [
            _ProfileItem(
              icon: Icons.person_outline,
              label: 'Personal information',
              onTap: () => _notice(context, 'Personal information'),
            ),
            _ProfileItem(
              icon: Icons.location_on_outlined,
              label: 'Delivery addresses',
              onTap: () => _notice(context, 'Delivery addresses'),
            ),
            _ProfileItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => _notice(context, 'Notification preferences'),
            ),
            _ProfileItem(
              icon: Icons.local_offer_outlined,
              label: 'Offers & promotions',
              onTap: () => _notice(context, 'Offers and promotions'),
            ),
            _ProfileItem(
              icon: Icons.help_outline,
              label: 'Help centre',
              onTap: () => _notice(context, 'Help centre'),
              showDivider: false,
            ),
          ],
        ),
      ),
    ],
  );

  void _notice(BuildContext context, String area) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$area selected')));
}

class _SweetShopScreen extends StatefulWidget {
  const _SweetShopScreen({required this.items, required this.onItemTap});
  final List<_Food> items;
  final ValueChanged<_Food> onItemTap;

  @override
  State<_SweetShopScreen> createState() => _SweetShopScreenState();
}

class _SweetShopScreenState extends State<_SweetShopScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Sri Lankan Sweet Shop')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Image.asset(
                          'assets/images/kavum.png',
                          height: 185,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: 185,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xD97A3528)],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Sweet traditions\nfrom around the island',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search kavum, kokis, dodol...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${items.length} traditional favourites',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .73,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => widget.onItemTap(item),
                  borderRadius: BorderRadius.circular(18),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: Image.asset(
                              item.image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.restaurant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  Text(
                                    'Rs. ${item.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.add_circle,
                                    color: AppColors.primaryDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: items.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.item, required this.onTap});
  final _Food item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: Image.asset(
              item.image,
              width: 125,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.restaurant,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs. ${item.price}  •  ★ ${item.rating}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: children);
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.name,
    required this.restaurant,
    required this.price,
    required this.status,
    required this.image,
  });
  final String name, restaurant, image;
  final int price;
  final AppStatus status;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  Text(restaurant),
                  Text(
                    'Rs. $price',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            StatusChip(status: status),
          ],
        ),
        const SizedBox(height: 14),
        AppButton(
          label: status == AppStatus.delivered ? 'Order again' : 'Track order',
          outlined: true,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == AppStatus.delivered
                    ? 'Added to your cart'
                    : 'Live tracking will open here',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
      if (showDivider) const Divider(height: 1),
    ],
  );
}

class _Food {
  const _Food(
    this.name,
    this.restaurant,
    this.price,
    this.rating,
    this.category,
    this.image,
  );
  final String name, restaurant, category, image;
  final int price;
  final double rating;
}

abstract final class _DemoCart {
  static final items = ValueNotifier<List<_Food>>([]);
  static final count = ValueNotifier<int>(0);
  static void add(_Food item) {
    items.value = [...items.value, item];
    count.value = items.value.length;
  }

  static void remove(_Food item) {
    items.value = [...items.value]..remove(item);
    count.value = items.value.length;
  }
}
