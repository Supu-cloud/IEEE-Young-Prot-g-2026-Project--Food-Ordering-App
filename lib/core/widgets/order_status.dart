import 'package:flutter/material.dart';

class OrderAppearance {
  const OrderAppearance(this.label, this.color, this.ink, this.icon);
  final String label;
  final Color color, ink;
  final IconData icon;
}

const ownerOrderAppearance = <String, OrderAppearance>{
  'placed': OrderAppearance(
    'New order',
    Color(0xFFF59E0B),
    Color(0xFF92400E),
    Icons.notifications_active_outlined,
  ),
  'accepted': OrderAppearance(
    'Accepted',
    Color(0xFF3B82F6),
    Color(0xFF1D4ED8),
    Icons.check,
  ),
  'confirmed': OrderAppearance(
    'Accepted',
    Color(0xFF3B82F6),
    Color(0xFF1D4ED8),
    Icons.check,
  ),
  'preparing': OrderAppearance(
    'Preparing',
    Color(0xFFF97316),
    Color(0xFF9A3412),
    Icons.soup_kitchen_outlined,
  ),
  'ready_for_pickup': OrderAppearance(
    'Ready for pickup',
    Color(0xFF22C55E),
    Color(0xFF166534),
    Icons.inventory_2_outlined,
  ),
  'rider_assigned': OrderAppearance(
    'Rider assigned',
    Color(0xFF22C55E),
    Color(0xFF166534),
    Icons.delivery_dining,
  ),
  'picked_up': OrderAppearance(
    'Picked up',
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
    Icons.delivery_dining,
  ),
  'out_for_delivery': OrderAppearance(
    'Out for delivery',
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
    Icons.delivery_dining,
  ),
  'delivered': OrderAppearance(
    'Delivered',
    Color(0xFF16A34A),
    Color(0xFF166534),
    Icons.check_circle_outline,
  ),
  'declined': OrderAppearance(
    'Declined',
    Color(0xFFEF4444),
    Color(0xFFB91C1C),
    Icons.cancel_outlined,
  ),
  'cancelled': OrderAppearance(
    'Cancelled',
    Color(0xFFEF4444),
    Color(0xFFB91C1C),
    Icons.cancel_outlined,
  ),
  'delivery_failed': OrderAppearance(
    'Delivery failed',
    Color(0xFFB91C1C),
    Color(0xFF991B1B),
    Icons.error_outline,
  ),
};
OrderAppearance appearance(String status) =>
    ownerOrderAppearance[status] ??
    OrderAppearance(
      status.replaceAll('_', ' '),
      Colors.grey,
      Colors.grey,
      Icons.help_outline,
    );

Color orderStatusColor(String status) => status == 'delivery_failed' ? const Color(0xFFEF4444) : appearance(status).color;
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip(this.status, {super.key, this.text});
  final String status;
  final String? text;
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = appearance(status);
    final color = orderStatusColor(status);
    return Chip(avatar: Icon(state.icon, size: 18, color: color),
      backgroundColor: Color.alphaBlend(color.withValues(alpha: .12), scheme.surface),
      side: BorderSide.none,
      label: Text(text ?? state.label, softWrap: true, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.brightness == Brightness.dark ? scheme.onSurface : state.ink)));
  }
}
class OrderStatusSurface extends StatelessWidget {
  const OrderStatusSurface({super.key, required this.status, required this.child});
  final String status;
  final Widget child;
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = orderStatusColor(status);
    return Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Color.alphaBlend(color.withValues(alpha: scheme.brightness == Brightness.dark ? .04 : .06), scheme.surface), border: Border(left: BorderSide(color: color, width: 5)), borderRadius: BorderRadius.circular(12)), child: child);
  }
}
const deliveryOrderStatus = <String, String>{'assigned':'rider_assigned','accepted':'rider_assigned','picked_up':'picked_up','out_for_delivery':'out_for_delivery','delivered':'delivered','failed':'delivery_failed','rejected':'ready_for_pickup'};
String deliveryVisualStatus(String status) => status == 'rejected' ? 'declined' : deliveryOrderStatus[status] ?? status;
String deliveryLabel(String status) => switch (status) { 'assigned' => 'Assigned', 'accepted' => 'Accepted', 'failed' => 'Could not deliver', 'rejected' => 'Rejected', _ => appearance(status).label };
