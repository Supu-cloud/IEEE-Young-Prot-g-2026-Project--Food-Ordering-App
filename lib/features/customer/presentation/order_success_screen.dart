import 'package:flutter/material.dart';
import '../data/customer_repository.dart';
import 'order_review_screen.dart';
import 'order_tracking_screen.dart';
import '../../../core/widgets/order_status.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.repository, required this.orders});
  final CustomerRepository repository;
  final List<Map<String, dynamic>> orders;
  @override
  Widget build(BuildContext context) {
    final id = orders.first['_id'] as String? ?? '';
    return Scaffold(appBar: AppBar(title: const Text('Order confirmed')), body: Center(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(28), children: [
      const Icon(Icons.check_circle, size: 96, color: Colors.green),
      const SizedBox(height: 20),
      Text('Ordered Successfully', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8), const Text('Your payment was confirmed and your order was saved.', textAlign: TextAlign.center),
      const SizedBox(height: 14), SelectableText('Order ID: ' + id, textAlign: TextAlign.center), const SizedBox(height: 26),
      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CustomerOrderDetailScreen(repository: repository, orderId: id))), child: const Text('View Order')),
      OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderTrackingScreen(repository: repository, orderId: id))), child: const Text('Track Order')),
      if (orders.length > 1) ...[const SizedBox(height: 14), Text(orders.length.toString() + ' restaurant orders were created.', textAlign: TextAlign.center)],
    ])));
  }
}

class CustomerOrderDetailScreen extends StatefulWidget {
  const CustomerOrderDetailScreen({super.key, required this.repository, required this.orderId});
  final CustomerRepository repository; final String orderId;
  @override State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}
class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  Map<String, dynamic>? order; Object? error; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { setState(() => loading = true); try { final value = await widget.repository.getTracking(widget.orderId); if (mounted) setState(() { order = value; error = null; }); } catch (failure) { if (mounted) setState(() => error = failure); } finally { if (mounted) setState(() => loading = false); } }
  @override Widget build(BuildContext context) {
    final value = order; final status = value?['status'] as String? ?? ''; final delivered = status == 'delivered'; final reviewed = value?['deliveryReview'] is Map; final restaurant = value?['restaurant']; final rider = value?['deliveryRider'];
    if (loading && value == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: const Text('Order details')), body: RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(20), children: [
      if (error != null) Text(error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      Text('Order #' + widget.orderId, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), OrderStatusSurface(status: status, child: OrderStatusChip(status, text: status.replaceAll('_', ' ').toUpperCase())),
      if (restaurant is Map) ...[Text((restaurant['name'] as String?) ?? 'Restaurant', style: Theme.of(context).textTheme.titleLarge), Text((restaurant['address'] as String?) ?? '')],
      const SizedBox(height: 10), for (final item in (value?['items'] as List? ?? []).whereType<Map>()) ListTile(contentPadding: EdgeInsets.zero, title: Text(item['quantity'].toString() + ' × ' + (item['name'] ?? 'Menu item').toString()), trailing: Text('LKR ' + item['price'].toString())),
      Text('Delivery address: ' + (value?['deliveryAddress'] ?? '').toString()), Text('Total: LKR ' + (value?['totalAmount'] ?? 0).toString(), style: Theme.of(context).textTheme.titleLarge), Text('Rider: ' + (rider is Map ? (rider['name'] ?? 'Assigned rider').toString() : 'Awaiting assignment').toString()), const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderTrackingScreen(repository: widget.repository, orderId: widget.orderId))), icon: const Icon(Icons.route), label: const Text('Track Order')),
      if (delivered && !reviewed) FilledButton.icon(onPressed: () async { final result = await Navigator.push<OrderData>(context, MaterialPageRoute(builder: (_) => OrderReviewScreen(repository: widget.repository, order: OrderData.fromJson(value ?? {}), onSaved: (_) {}))); if (result != null && mounted) load(); }, icon: const Icon(Icons.star), label: const Text('Leave Review')),
      if (reviewed) const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.verified, color: Colors.green), title: Text('Reviewed'), subtitle: Text('Thank you for rating this order.')),
    ])));
  }
}
