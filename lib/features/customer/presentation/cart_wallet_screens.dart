import 'package:flutter/material.dart';
import '../../../core/widgets/coordinate_fields.dart';
import '../../../core/network/image_url.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/checkout_controller.dart';
import 'stripe_checkout_screen.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({
    super.key,
    required this.controller,
    required this.onWallet,
  });
  final CheckoutController controller;
  final VoidCallback onWallet;
  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  CheckoutController get controller => widget.controller;
  late final _address = TextEditingController(text: controller.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final cart = controller.cart;
      if (_address.text != controller.address) {
        _address.value = TextEditingValue(
          text: controller.address,
          selection: TextSelection.collapsed(offset: controller.address.length),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshCart();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text('Cart', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            CheckoutFeedback(controller: controller),
            if (!controller.initialized || cart == null)
              TextButton(
                onPressed: controller.busy ? null : controller.initialize,
                child: const Text('Load cart and saved payment'),
              )
            else if (cart.items.isEmpty && !controller.recovering)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64),
                    SizedBox(height: 16),
                    Text('Your cart is empty'),
                    Text('Add something delicious from Home or Restaurants.'),
                  ],
                ),
              ),
            if (controller.recovering) ...[
              const Text(
                'This payment has been saved. Finish it in Wallet before changing the cart. Its reviewed items and prices stay unchanged.',
              ),
              const SizedBox(height: 12),
            ],
            if (cart != null && controller.quote == null) ...[
              for (final group in cart.groups.entries) ...[
                Text(
                  cart.restaurantNames[group.key] ?? 'Restaurant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final line in group.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AppCard(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (resolveImageUrl(line.menuItem.imageUrl)
                                  case final String url) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.square(
                                          dimension: 64,
                                          child: Icon(Icons.restaurant),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.menuItem.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Unit price: LKR ${line.menuItem.price.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'LKR ${(line.menuItem.price * line.quantity).toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove ${line.menuItem.name}',
                                onPressed: controller.editable
                                    ? () => controller.quantity(
                                        line.menuItem.id,
                                        0,
                                      )
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Decrease ${line.menuItem.name}',
                                onPressed: controller.editable
                                    ? () => controller.quantity(
                                        line.menuItem.id,
                                        line.quantity - 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${line.quantity}',
                                semanticsLabel: 'Quantity ${line.quantity}',
                              ),
                              IconButton(
                                tooltip: 'Increase ${line.menuItem.name}',
                                onPressed:
                                    controller.editable && line.quantity < 100
                                    ? () => controller.quantity(
                                        line.menuItem.id,
                                        line.quantity + 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (cart.items.isNotEmpty) ...[
                Text('Subtotal: LKR ${cart.totalAmount.toStringAsFixed(2)}'),
                const Text(
                  'Delivery fee and total payable are calculated by the server when you review your order.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  enabled: controller.editable,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                  ),
                  onChanged: (value) => controller.address = value,
                ),
                CoordinateFields(
                  latitude: controller.latitude,
                  longitude: controller.longitude,
                  enabled: controller.editable,
                  onChanged: controller.selectDeliveryLocation,
                ),
                if (controller.latitude.isNotEmpty &&
                    controller.longitude.isNotEmpty) ...[
                  const Text(
                    'Automatic address lookup is unavailable. Enter your delivery address above and confirm it matches the selected location.',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'My delivery address matches the selected location',
                    ),
                    value: !controller.addressConfirmationRequired,
                    onChanged: controller.editable
                        ? (value) =>
                              controller.confirmDeliveryAddress(value ?? false)
                        : null,
                  ),
                ],
                FilledButton(
                  onPressed: controller.busy ? null : controller.review,
                  child: const Text('Review order'),
                ),
              ],
            ],
            if (controller.quote case final Map<String, dynamic> quote) ...[
              PaymentSummary(quote: quote),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.busy ? null : widget.onWallet,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Proceed to Payment'),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class CustomerWalletScreen extends StatelessWidget {
  const CustomerWalletScreen({
    super.key,
    required this.controller,
    required this.onCart,
    required this.onPaid,
    this.presentPayment,
  });
  final CheckoutController controller;
  final VoidCallback onCart;
  final VoidCallback onPaid;
  final Future<void> Function(Map<String, dynamic>)? presentPayment;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Wallet / Payment',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        CheckoutFeedback(controller: controller),
        if (controller.confirmation != null) ...[
          const Icon(Icons.check_circle_outline, size: 48),
          Text(
            'Payment confirmed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Your paid orders are available in Orders.'),
        ],
        if (controller.quote case final Map<String, dynamic> quote) ...[
          Text(
            'Current payment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          PaymentSummary(quote: quote),
          const SizedBox(height: 20),
          const AppCard(
            child: ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Card • Stripe test payment'),
              subtitle: Text(
                'Choose your card securely in the payment sheet. Test payments only.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controller.busy
                ? null
                : () async {
                    final brightness = Theme.of(context).brightness;
                    final success = await controller.pay(
                      presentPayment ??
                          (attempt) =>
                              presentFoodiePayment(attempt, brightness),
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment confirmed. Your orders are ready to view.',
                          ),
                        ),
                      );
                      onPaid();
                    }
                  },
            child: Text(
              controller.attempt?['status'] == 'succeeded' ||
                      controller.attempt?['status'] == 'processing'
                  ? 'Verify payment'
                  : 'Pay Now',
            ),
          ),
        ] else ...[
          if (controller.recovering || !controller.initialized)
            FilledButton(
              onPressed: controller.busy ? null : controller.initialize,
              child: const Text('Resume saved payment'),
            )
          else ...[
            const Text(
              'Review your cart to see the items, delivery fee and total payable here.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCart,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Go to Cart'),
            ),
          ],
        ],
      ],
    ),
  );
}

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({super.key, required this.quote});
  final Map<String, dynamic> quote;
  String money(dynamic value) => (value as num).toStringAsFixed(2);
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group
            in (quote['groups'] as List? ?? [quote]).whereType<Map>()) ...[
          Text(
            group['restaurantName'] as String? ?? 'Restaurant',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final line in (group['items'] as List? ?? []).whereType<Map>())
            Text(
              '${line['quantity']} × ${line['name']} — LKR ${money(line['price'])} each',
            ),
          Text('Delivery: LKR ${money(group['deliveryFee'])}'),
          const Divider(),
        ],
        Text('Delivery to: ${quote['deliveryAddress']}'),
        Text('Subtotal: LKR ${money(quote['subtotal'])}'),
        Text('Delivery fee: LKR ${money(quote['deliveryFee'])}'),
        Text(
          'Total payable: LKR ${money(quote['totalAmount'])}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
  );
}

class CheckoutFeedback extends StatelessWidget {
  const CheckoutFeedback({super.key, required this.controller});
  final CheckoutController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (controller.busy) const LinearProgressIndicator(),
      if (controller.error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            controller.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );
}
