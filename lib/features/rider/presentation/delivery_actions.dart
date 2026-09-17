import 'package:flutter/material.dart';
import '../../operations/data/operations_repository.dart';

class DeliveryActions extends StatefulWidget {
  const DeliveryActions({super.key, required this.delivery, required this.repository, required this.onConfirmed});
  final Map<String, dynamic> delivery;
  final OperationsRepository repository;
  final ValueChanged<Map<String, dynamic>> onConfirmed;
  @override State<DeliveryActions> createState() => _DeliveryActionsState();
}
class _DeliveryActionsState extends State<DeliveryActions> {
  String? pending, error;
  bool confirming = false;
  Future<void> update(String status) async {
    if (pending != null || confirming) return;
    if (status == 'failed' || status == 'rejected') {
      setState(() => confirming = true);
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(status == 'failed' ? 'Could not deliver this order?' : 'Reject this assignment?'),
        content: Text(status == 'failed' ? 'Confirm that this delivery could not be completed. The order will be marked as delivery failed.' : 'The assignment will be returned to the restaurant.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go back')),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.warning_amber_rounded), label: Text(status == 'failed' ? 'Confirm failure' : 'Confirm rejection'))],
      ));
      if (!mounted) return;
      setState(() => confirming = false);
      if (confirmed != true) return;
    }
    setState(() { pending = status; error = null; });
    try {
      final updated = await widget.repository.deliveryStatus(widget.delivery['_id'] as String, status);
      if (mounted) widget.onConfirmed(updated);
    } catch (failure) { if (mounted) setState(() => error = failure.toString()); }
    finally { if (mounted) setState(() => pending = null); }
  }
  @override Widget build(BuildContext context) {
    final status = widget.delivery['status'] as String;
    final next = riderNext[status];
    final actions = <(String, String, IconData)>[
      if (next != null) (next, next == 'delivered' ? 'Mark Delivered' : next == 'picked_up' ? 'Mark picked up' : 'Start delivery', next == 'delivered' ? Icons.check : Icons.delivery_dining),
      if (['assigned','accepted','picked_up','out_for_delivery'].contains(status)) ('failed', 'Could Not Deliver', Icons.warning_amber_rounded),
      if (status == 'assigned') ('rejected', 'Reject assignment', Icons.close),
    ];
    Widget button((String, String, IconData) action) {
      final failure = ['failed', 'rejected'].contains(action.$1);
      return FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), backgroundColor: failure ? const Color(0xFFDC2626) : action.$1 == 'delivered' ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6), foregroundColor: failure ? Colors.white : const Color(0xFF101827)),
        onPressed: pending != null || confirming ? null : () => update(action.$1),
        icon: pending == action.$1 ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(action.$3, size: 20),
        label: Text(pending == action.$1 ? 'Saving…' : action.$2, textAlign: TextAlign.center, softWrap: true),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (error != null) Semantics(liveRegion: true, child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      LayoutBuilder(builder: (context, constraints) {
        // Stack when narrow or when accessibility text sizing needs more room.
        final horizontal = constraints.maxWidth >= 360 && MediaQuery.textScalerOf(context).scale(14) <= 18;
        if (!horizontal || actions.length != 2) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final action in actions) Padding(padding: const EdgeInsets.only(top: 10), child: button(action))]);
        return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: button(actions[0])), const SizedBox(width: 12), Expanded(child: button(actions[1]))]));
      }),
    ]);
  }
}
