import 'package:flutter/material.dart';
import '../../operations/data/operations_repository.dart';

import '../../../core/widgets/order_status.dart';
export '../../../core/widgets/order_status.dart' show appearance;

Map<String, dynamic> mergeOwnerOrder(
  Map<String, dynamic> current,
  Map<String, dynamic> updated,
) => {
  ...current,
  ...updated,
  if (updated['customer'] is String) 'customer': current['customer'],
  if (updated['restaurant'] is String) 'restaurant': current['restaurant'],
};

class OwnerOrderCard extends StatelessWidget {
  const OwnerOrderCard({
    super.key,
    required this.order,
    this.repository,
    this.onConfirmed,
    this.onTap,
    this.child,
  });
  final Map<String, dynamic> order;
  final OperationsRepository? repository;
  final ValueChanged<Map<String, dynamic>>? onConfirmed;
  final VoidCallback? onTap;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final state = appearance('${order['status']}');
    return Container(
      key: ValueKey('order-${order['_id']}-${order['status']}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          state.color.withValues(alpha: dark ? .04 : .06),
          theme.colorScheme.surface,
        ),
        border: Border(left: BorderSide(color: state.color, width: 5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Order #${order['_id']}',
                style: theme.textTheme.titleMedium,
              ),
              Chip(
                avatar: Icon(state.icon, color: state.color, size: 18),
                backgroundColor: state.color.withValues(
                  alpha: dark ? .15 : .12,
                ),
                side: BorderSide.none,
                label: Text(
                  state.label,
                  style: TextStyle(
                    color: dark ? theme.colorScheme.onSurface : state.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (child != null)
            child!
          else ...[
            Text(person(order['customer'])),
            for (final item in maps(order['items']))
              Text('${item['quantity']} × ${item['name']}'),
            Text(
              '${money(order['totalAmount'])} · Payment: ${label(order['paymentStatus'])}',
            ),
          ],
          if (repository != null && onConfirmed != null)
            OwnerOrderActions(
              order: order,
              repository: repository!,
              onConfirmed: onConfirmed!,
            ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text('View order details'),
            ),
        ],
      ),
    );
  }
}

class OwnerOrderActions extends StatefulWidget {
  const OwnerOrderActions({
    super.key,
    required this.order,
    required this.repository,
    required this.onConfirmed,
  });
  final Map<String, dynamic> order;
  final OperationsRepository repository;
  final ValueChanged<Map<String, dynamic>> onConfirmed;
  @override
  State<OwnerOrderActions> createState() => _OwnerOrderActionsState();
}

class _OwnerOrderActionsState extends State<OwnerOrderActions> {
  String? pending, error;
  Future<void> update(String status) async {
    if (pending != null) return;
    setState(() {
      pending = status;
      error = null;
    });
    try {
      final updated = await widget.repository.orderStatus(
        widget.order['_id'] as String,
        status,
      );
      if (mounted) widget.onConfirmed(updated);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] as String;
    final next = ownerNext[status];
    final actions = <String, String>{};
    if (next != null) {
      actions[next] = switch (status) {
        'placed' => 'Accept order',
        'accepted' => 'Confirm order',
        'confirmed' => 'Start preparing',
        _ => 'Ready for pickup',
      };
    }
    if (status == 'placed') {
      actions['declined'] = 'Decline order';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final action in actions.entries)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: action.key == 'declined'
                      ? appearance(action.key).ink
                      : appearance(action.key).color,
                  foregroundColor: action.key == 'declined'
                      ? Colors.white
                      : const Color(0xFF101827),
                ),
                onPressed: pending != null ? null : () => update(action.key),
                icon: pending == action.key
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(appearance(action.key).icon, size: 18),
                label: Text(pending == action.key ? 'Saving…' : action.value),
              ),
          ],
        ),
      ],
    );
  }
}
