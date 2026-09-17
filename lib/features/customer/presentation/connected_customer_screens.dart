import '../../../core/widgets/order_status.dart';
import '../../operations/presentation/role_widgets.dart' show LiveResource;
import '../../../core/theme/theme_controller.dart';
import '../../../core/localization/language_controller.dart';
import 'order_tracking_screen.dart';
import 'order_success_screen.dart';
import 'order_review_screen.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../data/customer_repository.dart';
import 'feast_video.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.repository,
    this.restaurantsOnly = false,
    this.addToCart,
    this.profileAction,
  });

  final CustomerRepository repository;
  final bool restaurantsOnly;
  final Future<void> Function(String)? addToCart;
  final Widget? profileAction;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _query = '';
  String _category = 'All';
  late Future<List<RestaurantData>> _restaurants;
  late Future<FoodDiscoveryData> _foods;
  final Set<String> _adding = {};

  @override
  void initState() {
    super.initState();
    if (widget.restaurantsOnly) {
      _restaurants = widget.repository.getRestaurants();
    } else {
      _foods = widget.repository.getFoodDiscovery();
    }
  }

  Future<void> _reload() async {
    if (widget.restaurantsOnly) {
      setState(() => _restaurants = widget.repository.getRestaurants());
      await _restaurants;
    } else {
      setState(() => _foods = widget.repository.getFoodDiscovery());
      await _foods;
    }
  }

  @override
  Widget build(BuildContext context) => widget.restaurantsOnly
      ? _buildRestaurants(context)
      : _buildFoods(context);

  Widget _buildFoods(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      try {
        await _reload();
      } on Object {
        /* FutureBuilder shows the error. */
      }
    },
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FeastVideo(),
                const SizedBox(height: 20),
                Text(
                  'What are you craving?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search food or restaurant',
                  ),
                ),
              ],
            ),
          ),
        ),
        FutureBuilder<FoodDiscoveryData>(
          future: _foods,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: _ErrorView(
                  error: snapshot.error,
                  onRetry: () {
                    _reload().catchError((Object _) {});
                  },
                ),
              );
            }
            final data = snapshot.data!;
            final categories = [
              'All',
              ...data.foods.map((food) => food.item.category).toSet(),
            ];
            final selectedCategory = categories.contains(_category)
                ? _category
                : 'All';
            final query = _query.trim().toLowerCase();
            final foods = data.foods
                .where(
                  (food) =>
                      (selectedCategory == 'All' ||
                          food.item.category == selectedCategory) &&
                      '${food.item.name} ${food.item.description} ${food.restaurant.name}'
                          .toLowerCase()
                          .contains(query),
                )
                .toList();
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.builder(
                itemCount: foods.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.failedMenus > 0) ...[
                          const Text('Some menus could not be loaded.'),
                          TextButton(
                            onPressed: () {
                              _reload().catchError((Object _) {});
                            },
                            child: const Text('Retry menus'),
                          ),
                        ],
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: categories
                                .map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: selectedCategory == category,
                                      onSelected: (_) =>
                                          setState(() => _category = category),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Food for you',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (foods.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              data.failedMenus > 0
                                  ? 'Try loading the menus again.'
                                  : 'No food items found.',
                            ),
                          ),
                      ],
                    );
                  }
                  final food = foods[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RestaurantMenuScreen(
                                repository: widget.repository,
                                restaurant: food.restaurant,
                                addToCart: widget.addToCart,
                                profileAction: widget.profileAction,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.storefront_outlined, size: 18),
                          label: Text(
                            '${food.restaurant.name}${food.restaurant.isOpen ? '' : ' • Closed'}',
                          ),
                        ),
                        _MenuCard(
                          item: food.item,
                          canAdd:
                              food.restaurant.isOpen &&
                              !_adding.contains(food.item.id),
                          onAdd: () => _addFood(food.item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
  );

  Future<void> _addFood(MenuItemData item) async {
    if (_adding.contains(item.id)) return;
    setState(() => _adding.add(item.id));
    try {
      if (widget.addToCart != null) {
        await widget.addToCart!(item.id);
      } else {
        await widget.repository.addToCart(item.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _adding.remove(item.id));
    }
  }

  Widget _buildRestaurants(
    BuildContext context,
  ) => FutureBuilder<List<RestaurantData>>(
    future: _restaurants,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _ErrorView(
          error: snapshot.error,
          onRetry: () {
            _reload().catchError((Object _) {});
          },
        );
      }
      final restaurants = (snapshot.data ?? []).where((restaurant) {
        final query = _query.trim().toLowerCase();
        final categoryMatch =
            _category == 'All' || restaurant.category == _category;
        return categoryMatch &&
            (query.isEmpty ||
                '${restaurant.name} ${restaurant.category} ${restaurant.address}'
                    .toLowerCase()
                    .contains(query));
      }).toList();
      final categories = [
        'All',
        ...{...snapshot.data!.map((restaurant) => restaurant.category)},
      ];
      return RefreshIndicator(
        onRefresh: () async {
          try {
            await _reload();
          } on Object {
            /* FutureBuilder shows the error. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('Delivering to'), Text('Your saved address')],
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search restaurants or cuisine',
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 22),
            if (snapshot.data!.isNotEmpty)
              _FeaturedRestaurant(restaurant: snapshot.data!.first),
            const SizedBox(height: 22),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories
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
            Text(
              'Restaurants near you',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (restaurants.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No restaurants found.'),
                ),
              ),
            ...restaurants.map(
              (restaurant) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _RestaurantCard(
                  restaurant: restaurant,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantMenuScreen(
                        repository: widget.repository,
                        restaurant: restaurant,
                        addToCart: widget.addToCart,
                        profileAction: widget.profileAction,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({
    super.key,
    required this.repository,
    required this.restaurant,
    this.addToCart,
    this.profileAction,
  });

  final CustomerRepository repository;
  final RestaurantData restaurant;
  final Future<void> Function(String)? addToCart;
  final Widget? profileAction;

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late Future<List<MenuItemData>> _menu;

  @override
  void initState() {
    super.initState();
    _menu = widget.repository.getMenu(widget.restaurant.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.restaurant.name),
      actions: [if (widget.profileAction != null) widget.profileAction!],
    ),
    body: FutureBuilder<List<MenuItemData>>(
      future: _menu,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(
            error: snapshot.error,
            onRetry: () => setState(
              () => _menu = widget.repository.getMenu(widget.restaurant.id),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No available menu items.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MenuCard(
                    item: item,
                    canAdd: widget.restaurant.isOpen,
                    onAdd: () async {
                      try {
                        if (widget.addToCart != null) {
                          await widget.addToCart!(item.id);
                        } else {
                          await widget.repository.addToCart(item.id);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                            ),
                          );
                        }
                      } on Object catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_message(error))),
                          );
                        }
                      }
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({
    super.key,
    required this.repository,
    this.refresh,
  });
  final Listenable? refresh;

  final CustomerRepository repository;

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  int revision = 0;
  @override void initState() { super.initState(); widget.refresh?.addListener(_refreshOrders); }
  void _refreshOrders() { if (mounted) setState(() => revision++); }
  @override void didUpdateWidget(covariant CustomerOrdersScreen old) {
    super.didUpdateWidget(old);
    if (old.refresh != widget.refresh) { old.refresh?.removeListener(_refreshOrders); widget.refresh?.addListener(_refreshOrders); }
  }
  @override void dispose() { widget.refresh?.removeListener(_refreshOrders); super.dispose(); }
  @override Widget build(BuildContext context) => LiveResource<List<OrderData>>(
    resourceKey: revision, load: widget.repository.getOrders,
    builder: (context, orders, reload) => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
      Text('${orders.length} orders · ${orders.where((order) => order.status == 'delivered').length} delivered'),
      if (orders.isEmpty) const Text('You have no orders yet.'),
      for (final order in orders) _OrderCard(key: ValueKey(order.id), order: order, repository: widget.repository, onChanged: reload,
        onConfirmed: (updated) {
          LiveResource.commit<List<OrderData>>(context, (current) => current.map((item) => item.id == updated.id ? updated : item).toList());
          reload();
        }),
    ]),
  );
}

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.repository,
    this.theme,
    this.language,
  });
  final ThemeController? theme;
  final LanguageController? language;
  final CustomerRepository repository;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late Future<CustomerProfileData> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.repository.getProfile();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.theme != null)
        Padding(
          padding: const EdgeInsets.all(20),
          child: ThemeSelector(controller: widget.theme!),
        ),
      if (widget.language != null)
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: LanguageSelector(controller: widget.language!)),
      Expanded(
        child: FutureBuilder<CustomerProfileData>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                error: snapshot.error,
                onRetry: () =>
                    setState(() => _profile = widget.repository.getProfile()),
              );
            }
            final profile = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Center(child: Text(profile.email)),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text(profile.phone ?? 'Add phone number'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(profile.address ?? 'Add delivery address'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit profile'),
                        onTap: () => _editProfile(profile),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );

  Future<void> _editProfile(CustomerProfileData profile) async {
    final name = TextEditingController(text: profile.name);
    final phone = TextEditingController(text: profile.phone);
    final address = TextEditingController(text: profile.address);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
    try {
      await widget.repository.updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
        address: address.text.trim(),
      );
      if (mounted) setState(() => _profile = widget.repository.getProfile());
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onTap});
  final RestaurantData restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _NetworkImage(url: restaurant.imageUrl, width: 112, height: 104),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    restaurant.category,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.isOpen ? 'Open now' : 'Closed',
                    style: TextStyle(
                      color: restaurant.isOpen
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
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

class _FeaturedRestaurant extends StatelessWidget {
  const _FeaturedRestaurant({required this.restaurant});
  final RestaurantData restaurant;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(
      alignment: Alignment.bottomLeft,
      children: [
        _NetworkImage(
          url: restaurant.imageUrl,
          width: double.infinity,
          height: 190,
        ),
        Container(
          height: 190,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.imageOverlay],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Featured near you',
                style: TextStyle(
                  color: AppColors.heroAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                restaurant.name,
                style: const TextStyle(
                  color: AppColors.onImage,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                restaurant.category,
                style: const TextStyle(color: AppColors.onImageSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.onAdd,
    this.canAdd = true,
  });
  final MenuItemData item;
  final VoidCallback onAdd;
  final bool canAdd;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        _NetworkImage(url: item.imageUrl, width: 82, height: 82),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 7),
              Text(
                'Rs. ${item.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Add ${item.name} to cart',
          onPressed: item.available && canAdd ? onAdd : null,
          icon: const Icon(Icons.add_circle),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({super.key, required this.order, required this.repository, required this.onChanged, required this.onConfirmed});
  final OrderData order;
  final CustomerRepository repository;
  final VoidCallback onChanged;
  final ValueChanged<OrderData> onConfirmed;
  @override State<_OrderCard> createState() => _OrderCardState();
}
class _OrderCardState extends State<_OrderCard> {
  bool busy = false;
  String? error;
  @override Widget build(BuildContext context) {
    final order = widget.order;
    return OrderStatusSurface(key: ValueKey('customer-${order.id}-${order.status}'), status: order.status, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(order.restaurantName ?? 'Restaurant', style: Theme.of(context).textTheme.titleMedium), OrderStatusChip(order.status)]),
      if (order.checkoutId != null) Text('Checkout: ${order.checkoutId}'),
      Text(order.items.map((item) => '${item.quantity}x ${item.name}').join(', ')),
      Text('Rs. ${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
      TextButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => order.status == 'delivered' ? CustomerOrderDetailScreen(repository: widget.repository, orderId: order.id) : OrderTrackingScreen(repository: widget.repository, orderId: order.id))); widget.onChanged(); }, icon: const Icon(Icons.local_shipping_outlined), label: Text(order.status == 'delivered' ? 'View Order' : 'Track Order')),
      if (order.status == 'delivered' && order.deliveryReview == null)
        FilledButton.icon(onPressed: busy ? null : () async { final saved = await Navigator.push<OrderData>(context, MaterialPageRoute(builder: (_) => OrderReviewScreen(repository: widget.repository, order: order, onSaved: (_) {}))); if (saved != null && mounted) widget.onConfirmed(saved); }, icon: const Icon(Icons.star), label: const Text('Leave Review')),
      if (order.status == 'delivered' && order.deliveryReview != null)
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.verified, color: Colors.green), title: Text('Reviewed')),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (order.status == 'placed') TextButton.icon(style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), onPressed: busy ? null : () async {
        setState(() { busy = true; error = null; });
        try { final updated = await widget.repository.cancelOrder(order.id); if (mounted) widget.onConfirmed(updated); }
        catch (failure) { if (mounted) setState(() => error = _message(failure)); }
        finally { if (mounted) setState(() => busy = false); }
      }, icon: const Icon(Icons.cancel_outlined), label: Text(busy ? 'Cancelling…' : 'Cancel order')),
    ]));
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.url,
    required this.width,
    required this.height,
  });
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final apiOrigin = AppConfig.apiBaseUrl.replaceFirst('/api', '');
    final resolvedUrl = imageUrl == null || imageUrl.isEmpty
        ? null
        : imageUrl.startsWith('http')
        ? imageUrl.replaceFirst(RegExp(r'^https?://localhost:\d+'), apiOrigin)
        : '${AppConfig.apiBaseUrl.replaceFirst('/api', '')}${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}';
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: resolvedUrl == null
          ? Icon(Icons.restaurant, color: Theme.of(context).colorScheme.primary)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.restaurant,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_message(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    ),
  );
}

String _message(Object? error) => error is ApiException
    ? error.message
    : error is StateError
    ? error.message.toString()
    : 'Unable to load data from the backend.';
