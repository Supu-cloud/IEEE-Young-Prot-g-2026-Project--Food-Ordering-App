import 'package:flutter/material.dart';
import '../data/customer_repository.dart';
import 'order_tracking_screen.dart';

class CheckoutOrdersScreen extends StatelessWidget {
  const CheckoutOrdersScreen({
    super.key,
    required this.repository,
    required this.orders,
    required this.quote,
    required this.checkoutId,
  });
  final CustomerRepository repository;
  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic> quote;
  final String checkoutId;
  @override
  Widget build(BuildContext context) {
    final names = {
      for (final group in (quote['groups'] as List? ?? []).whereType<Map>())
        group['restaurant']: group['restaurantName'],
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Payment confirmed')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'One payment - ${orders.length} restaurant orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SelectableText('Checkout: $checkoutId'),
            Text('Total paid: LKR ${quote['totalAmount']}'),
            const Text(
              'Each restaurant prepares and delivers its order separately. Track each delivery below or from Orders.',
            ),
            for (final order in orders)
              Card(
                child: ListTile(
                  title: Text(
                    names[order['restaurant']] as String? ?? 'Restaurant',
                  ),
                  subtitle: Text(
                    'Order ${order['_id']}\nLKR ${order['totalAmount']} - paid',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => OrderTrackingScreen(
                        repository: repository,
                        orderId: order['_id'] as String,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
