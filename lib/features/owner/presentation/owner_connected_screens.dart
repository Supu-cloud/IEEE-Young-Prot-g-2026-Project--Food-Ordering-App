import 'package:flutter/material.dart';
import 'owner_order_card.dart';
import '../../../core/network/image_url.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/role_widgets.dart';
import '../../operations/presentation/account_order_screens.dart';

class OwnerOrdersConnected extends StatefulWidget {
  const OwnerOrdersConnected({super.key, required this.repository}); final OperationsRepository repository;
  @override State<OwnerOrdersConnected> createState() => _OwnerOrdersConnectedState();
}
class _OwnerOrdersConnectedState extends State<OwnerOrdersConnected> {
  String status = '';
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'Order status'), items: [const DropdownMenuItem(value: '', child: Text('All orders')), ...orderStatuses.map((value) => DropdownMenuItem(value: value, child: Text(appearance(value).label)))], onChanged: (value) => setState(() => status = value ?? ''))),
    Expanded(child: LiveResource<List<Map<String, dynamic>>>(resourceKey: status, load: () => widget.repository.list('/owner/orders', query: {if (status.isNotEmpty) 'status': status}), builder: (context, orders, reload) => roleList([
      if (orders.isEmpty) const Text('No orders match this status.'),
      Text('${orders.length} orders'),
      ...orders.map((order) => OwnerOrderCard(key: ValueKey(order['_id']), order: order, repository: widget.repository,
        onConfirmed: (updated) {
          LiveResource.commit<List<Map<String, dynamic>>>(context, (current) => current.map((item) => item['_id'] == updated['_id'] ? mergeOwnerOrder(item, updated) : item).where((item) => status.isEmpty || item['status'] == status).toList());
          reload();
        },
        onTap: () => openPage(context, 'Order details', OperationsOrderDetail(repository: widget.repository, id: order['_id'] as String)))),
    ]))),
  ]);
}
class OwnerMenuConnected extends StatefulWidget {
  const OwnerMenuConnected({super.key, required this.repository}); final OperationsRepository repository;
  @override State<OwnerMenuConnected> createState() => _OwnerMenuConnectedState();
}
class _OwnerMenuConnectedState extends State<OwnerMenuConnected> {
  String query = '', availability = 'all';
  @override Widget build(BuildContext context) => LiveResource<List<Map<String, dynamic>>>(load: () => widget.repository.list('/owner/menu'), builder: (context, items, reload) => roleList([
    title(context, 'Menu'),
    FilledButton.icon(onPressed: () => openPage(context, 'Add menu item', OwnerMenuEditor(repository: widget.repository)), icon: const Icon(Icons.add), label: const Text('Add menu item')),
    const SizedBox(height: 12),
    TextField(decoration: const InputDecoration(labelText: 'Search name or category'), onChanged: (value) => setState(() => query = value.toLowerCase())),
    DropdownButton<String>(value: availability, items: const [DropdownMenuItem(value: 'all', child: Text('All items')), DropdownMenuItem(value: 'yes', child: Text('Available')), DropdownMenuItem(value: 'no', child: Text('Unavailable'))], onChanged: (value) => setState(() => availability = value!)),
    if (items.isEmpty) const Text('No menu items yet. Create your restaurant in Restaurant, then add food here.'),
    for (final item in items.where((item) => '${item['name']} ${item['category']}'.toLowerCase().contains(query) && (availability == 'all' || (availability == 'yes') == (item['available'] == true)))) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (resolveImageUrl(item['imageUrl'] as String?) case final String url) Image.network(url, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.restaurant, size: 48)),
      Text('${item['name']}', style: Theme.of(context).textTheme.titleLarge), Text('${item['category']} • ${money(item['price'])}'), Text('${item['description'] ?? ''}'),
      Wrap(spacing: 8, children: [
        TextButton(onPressed: () => openPage(context, 'Edit menu item', OwnerMenuEditor(repository: widget.repository, id: item['_id'] as String)), child: const Text('Edit')),
        RoleAction(title: item['available'] == true ? 'Make unavailable' : 'Make available', action: () async { await widget.repository.request('/menu/${item['_id']}/toggle', method: 'PATCH'); await reload(); }),
        RoleAction(title: 'Delete', icon: Icons.delete_outline, confirm: 'Delete ${item['name']}? This cannot be undone.', action: () async { await widget.repository.request('/menu/${item['_id']}', method: 'DELETE'); await reload(); }),
      ]),
    ]))),
  ]));
}
class OwnerMenuEditor extends StatefulWidget {
  const OwnerMenuEditor({super.key, required this.repository, this.id}); final OperationsRepository repository; final String? id;
  @override State<OwnerMenuEditor> createState() => _OwnerMenuEditorState();
}
class _OwnerMenuEditorState extends State<OwnerMenuEditor> {
  final form = GlobalKey<FormState>(); final values = <String,String>{};
  @override Widget build(BuildContext context) => LiveResource<Map<String, dynamic>>(poll: false, load: () async => {'restaurant': await widget.repository.request('/owner/restaurant'), 'item': widget.id == null ? {} : await widget.repository.object('/owner/menu/${widget.id}')}, builder: (context, data, reload) {
    final restaurant = map(data['restaurant']); final item = map(data['item']);
    if (restaurant.isEmpty) return roleList([const Text('Create your restaurant in the Restaurant tab before adding menu items.')]);
    return Form(key: form, child: roleList([
      for (final entry in {'name':'Item name','category':'Category','description':'Description','price':'Price (LKR)','imageUrl':'Image URL'}.entries) Padding(padding: const EdgeInsets.only(bottom: 16), child: TextFormField(initialValue: item[entry.key]?.toString() ?? '', decoration: InputDecoration(labelText: entry.value), keyboardType: entry.key == 'price' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, onSaved: (value) => values[entry.key] = value!.trim(), validator: (value) {
        if (['name','category'].contains(entry.key) && (value?.trim().isEmpty ?? true)) return 'Required';
        if (entry.key == 'price' && ((double.tryParse(value ?? '') ?? 0) <= 0 || !(double.tryParse(value ?? '') ?? 0).isFinite)) return 'Enter a positive price';
        if (entry.key == 'imageUrl' && value!.trim().isNotEmpty && !['http','https'].contains(Uri.tryParse(value.trim())?.scheme)) return 'Enter an HTTP or HTTPS image URL';
        return null;
      })),
      RoleAction(title: 'Save item', icon: Icons.save_outlined, action: () async { if (!form.currentState!.validate()) return; form.currentState!.save(); await widget.repository.request(widget.id == null ? '/menu' : '/menu/${widget.id}', method: widget.id == null ? 'POST' : 'PUT', data: {...values, 'price': double.parse(values['price']!), 'restaurant': restaurant['_id']}); if (context.mounted) Navigator.pop(context); }),
    ]));
  });
}
class OwnerAnalyticsConnected extends StatelessWidget {
  const OwnerAnalyticsConnected({super.key, required this.repository}); final OperationsRepository repository;
  @override Widget build(BuildContext context) => LiveResource<Map<String,dynamic>>(load: () => repository.object('/owner/analytics'), builder: (context, data, reload) => roleList([
    title(context, 'Restaurant analytics'),
    metrics(context, {for (final entry in map(data['summary']).entries) label(entry.key): entry.key.toLowerCase().contains('revenue') || entry.key == 'averageOrderValue' ? money(entry.value) : entry.value}),
    const Text('Internal test earnings from the backend; no bank payout.'),
    title(context, 'Popular items'),
    for (final item in maps(data['popularItems'])) ListTile(title: Text('${item['name'] ?? item['_id']}'), subtitle: Text('Quantity: ${item['quantity'] ?? item['totalQuantity'] ?? 0} • ${money(item['revenue'])}')),
    title(context, 'Recent sales'),
    for (final order in maps(data['recentSales'])) OrderTile(order: order, onTap: () => openPage(context, 'Order details', OperationsOrderDetail(repository: repository, id: order['_id'] as String))),
  ]));
}
