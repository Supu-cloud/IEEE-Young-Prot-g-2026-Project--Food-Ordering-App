import 'package:flutter/material.dart';
import '../data/customer_repository.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({
    super.key,
    required this.repository,
    required this.order,
    required this.onSaved,
  });
  final CustomerRepository repository;
  final OrderData order;
  final ValueChanged<OrderData> onSaved;

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  int restaurantRating = 0;
  int riderRating = 0;
  int serviceRating = 0;
  bool busy = false;
  String? error;
  final restaurantComment = TextEditingController();
  final riderComment = TextEditingController();

  @override
  void dispose() {
    restaurantComment.dispose();
    riderComment.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || restaurantRating == 0 || riderRating == 0 || serviceRating == 0) {
      setState(() => error = 'Choose a 1–5 star rating for each section.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      // The existing backend requires receipt confirmation before a review.
      await widget.repository.confirmReceipt(widget.order.id);
      final saved = await widget.repository.submitDeliveryReview(
        orderId: widget.order.id,
        restaurantRating: restaurantRating,
        riderRating: riderRating,
        serviceRating: serviceRating,
        restaurantComment: restaurantComment.text.trim(),
        riderComment: riderComment.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved(saved);
      Navigator.pop(context);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget stars(String title, int value, ValueChanged<int> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Row(children: [
          for (var index = 1; index <= 5; index++)
            IconButton(
              tooltip: '$index stars',
              onPressed: busy ? null : () => setState(() => onChanged(index)),
              icon: Icon(index <= value ? Icons.star : Icons.star_border),
              color: Colors.amber.shade700,
            ),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    final riderName = widget.order.deliveryRider?['name'] as String? ?? 'Assigned rider';
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your order')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (widget.order.restaurantImageUrl case final image?)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(image, height: 150, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(height: 20)),
          ),
        const SizedBox(height: 16),
        Text(widget.order.restaurantName ?? 'Restaurant',
            style: Theme.of(context).textTheme.headlineSmall),
        const Text('Your order was delivered. Tell us how it went.'),
        const SizedBox(height: 18),
        stars('Restaurant and food', restaurantRating,
            (value) => restaurantRating = value),
        TextField(
          controller: restaurantComment,
          maxLength: 2000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Food comment (optional)',
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          CircleAvatar(
            backgroundImage: widget.order.deliveryRider?['profilePicture'] is String && (widget.order.deliveryRider?['profilePicture'] as String).isNotEmpty
                ? NetworkImage(widget.order.deliveryRider?['profilePicture'] as String)
                : null,
            child: widget.order.deliveryRider?['profilePicture'] is String && (widget.order.deliveryRider?['profilePicture'] as String).isNotEmpty ? null : const Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Text(riderName, style: Theme.of(context).textTheme.titleMedium),
        ]),
        stars('Rider', riderRating, (value) => riderRating = value),
        stars('Delivery service', serviceRating,
            (value) => serviceRating = value),
        TextField(
          controller: riderComment,
          maxLength: 2000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Delivery comment (optional)',
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : submit,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(busy ? 'Saving review…' : 'Submit review'),
        ),
        const SizedBox(height: 8),
        const Text('Optional rider tips are not enabled until a verified tip payment flow is available.'),
      ]),
    );
  }
}
