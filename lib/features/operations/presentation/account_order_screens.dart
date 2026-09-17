import 'package:flutter/material.dart';
import '../../owner/presentation/owner_order_card.dart';
import '../../../core/di/app_dependencies.dart';
import '../../customer/presentation/connected_customer_screens.dart';
import '../data/operations_repository.dart';
import 'role_widgets.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override Widget build(BuildContext context) => Column(children: [
    ListTile(title: Text(dependencies.session.role?.label ?? 'Account'), subtitle: const Text('Authenticated Foodie account')),
    Expanded(child: CustomerProfileScreen(repository: dependencies.customerRepository, theme: dependencies.theme, language: dependencies.language)),
    Padding(padding: const EdgeInsets.all(16), child: RoleAction(title: 'Sign out', icon: Icons.logout, confirm: 'Sign out of Foodie on this device?', action: dependencies.session.signOut)),
  ]);
}
class AccountAction extends StatelessWidget {
  const AccountAction({super.key, required this.dependencies}); final AppDependencies dependencies;
  @override Widget build(BuildContext context) => IconButton(tooltip: 'Profile', icon: const Icon(Icons.person_outline), onPressed: () => openPage(context, 'Profile', AccountScreen(dependencies: dependencies)));
}

class OperationsOrderDetail extends StatelessWidget {
  const OperationsOrderDetail({super.key, required this.repository, required this.id, this.admin = false});
  final OperationsRepository repository; final String id; final bool admin;
  @override Widget build(BuildContext context) => LiveResource<Map<String, dynamic>>(
    load: () => repository.object(admin ? '/admin/orders/$id' : '/owner/orders/$id'),
    builder: (context, order, reload) => roleList([
      title(context, 'Order #${order['_id']}'),
      OwnerOrderCard(order: order, repository: repository,
        child: OrderInformation(order: order, showStatus: false),
        onConfirmed: (updated) {
          LiveResource.commit<Map<String, dynamic>>(context, (current) => mergeOwnerOrder(current, updated));
          reload();
        }),
      if (order['status'] == 'ready_for_pickup') RoleAction(title: 'Assign rider', icon: Icons.delivery_dining, action: () async { await assignRider(context, repository, id); await reload(); }),
    ]),
  );
}
class OrderInformation extends StatelessWidget {
  const OrderInformation({super.key, required this.order, this.showStatus = true}); final Map<String, dynamic> order; final bool showStatus;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (showStatus) StatusPill('${order['status']}'),
    Text('Placed: ${localTime(order['createdAt'])}'),
    ListTile(contentPadding: EdgeInsets.zero, title: Text('Customer: ${person(order['customer'])}'), subtitle: Text('${map(order['customer'])['phone'] ?? ''}\n${order['deliveryAddress'] ?? ''}')),
    Text('Restaurant: ${person(order['restaurant'])}'),
    if (map(order['restaurant'])['address'] != null) Text('Pickup: ${map(order['restaurant'])['address']}'),
    if (map(order['restaurant'])['phone'] != null) Text('Restaurant phone: ${map(order['restaurant'])['phone']}'),
    Text('Rider: ${person(order['deliveryRider'])}'),
    if (map(order['deliveryRider'])['phone'] != null) Text('Rider phone: ${map(order['deliveryRider'])['phone']}'),
    const Divider(),
    for (final item in maps(order['items'])) ListTile(contentPadding: EdgeInsets.zero, title: Text('${item['quantity']} × ${item['name']}'), subtitle: Text('${money(item['price'])} each')),
    Text('Subtotal: ${money(order['subtotal'])}'), Text('Delivery: ${money(order['deliveryFee'])}'),
    Text('Total: ${money(order['totalAmount'])}', style: Theme.of(context).textTheme.titleLarge),
    Text('Payment: ${label(order['paymentStatus'])} • ${label(order['paymentMethod'])}'),
    if (order['note'] != null) Text('Note: ${order['note']}'),
    if (order['settlement'] is Map) Text('Internal test earnings: restaurant ${money(map(order['settlement'])['restaurantAmount'])} (${label(map(order['settlement'])['restaurantStatus'])}), rider ${money(map(order['settlement'])['riderAmount'])} (${label(map(order['settlement'])['riderStatus'])}).'),
    for (final field in ['confirmedAt','preparingAt','readyForPickupAt','riderAssignedAt','pickedUpAt','outForDeliveryAt','deliveredAt','cancelledAt','deliveryFailedAt'])
      if (order[field] != null) Text('$field: ${localTime(order[field])}'),
    const SizedBox(height: 16),
  ]);
}
Future<void> assignRider(BuildContext context, OperationsRepository repository, String order) async {
  final riders = await repository.list('/deliveries/available-riders');
  if (!context.mounted) return;
  final chosen = await showDialog<String>(context: context, builder: (context) => SimpleDialog(title: const Text('Choose an available rider'), children: [
    if (riders.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No approved online riders are available.')),
    for (final rider in riders) SimpleDialogOption(onPressed: () => Navigator.pop(context, map(rider['user'])['_id'] as String), child: Text('${person(rider['user'])} • ${rider['vehicleType'] ?? ''} ${rider['vehicleNumber'] ?? ''}')),
  ]));
  if (chosen == null || !context.mounted) return;
  if (await confirmAction(context, 'Assign rider', 'Assign the selected rider to this order?')) await repository.assignRider(order, chosen);
}
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap}); final Map<String, dynamic> order; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(child: ListTile(isThreeLine: true, title: Text('Order #${order['_id']}'), subtitle: Text('${person(order['customer'])} • ${money(order['totalAmount'])}\n${label(order['status'])} • ${label(order['paymentStatus'])}\n${localTime(order['createdAt'])}'), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
