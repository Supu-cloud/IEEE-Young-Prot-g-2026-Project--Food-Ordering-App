import '../../../core/widgets/order_status.dart';
import '../../../core/config/map_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/customer_repository.dart';
import '../../operations/data/operations_repository.dart' show map;

const trackingSteps = <(String, String, String)>[
  ('placed', 'Order placed', 'placedAt'),
  ('accepted', 'Accepted', 'confirmedAt'),
  ('confirmed', 'Confirmed', 'confirmedAt'),
  ('preparing', 'Preparing', 'preparingAt'),
  ('ready_for_pickup', 'Ready for pickup', 'readyForPickupAt'),
  ('rider_assigned', 'Rider assigned', 'riderAssignedAt'),
  ('picked_up', 'Picked up', 'pickedUpAt'),
  ('out_for_delivery', 'Out for delivery', 'outForDeliveryAt'),
  ('delivered', 'Delivered', 'deliveredAt'),
];

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.repository,
    required this.orderId,
  });
  final CustomerRepository repository;
  final String orderId;
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _route;
  String? _error;
  DateTime? _updated;
  Timer? _timer;
  bool _loading = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_foreground) _load();
  }

  Future<void> _load() async {
    if (_loading || !mounted) return;
    _timer?.cancel();
    setState(() => _loading = true);
    try {
      final order = await widget.repository.getTracking(widget.orderId);
      Map<String, dynamic>? route;
      if (order['pickupLocation'] != null && order['deliveryLocation'] != null) {
        try { route = await widget.repository.getOrderRoute(widget.orderId); } catch (_) { /* status tracking remains useful when route service is unavailable */ }
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _route = route;
        _error = null;
        _updated = DateTime.now();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_foreground) _timer = Timer(const Duration(seconds: 7), _load);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = order?['status'] as String? ?? '';
    final terminal = [
      'cancelled',
      'declined',
      'delivery_failed',
    ].contains(status);
    final rider = order?['deliveryRider'];
    final restaurantPoint = parseCoordinates(map(_route?['restaurant'])['coordinates']);
    final customerPoint = parseCoordinates(map(_route?['customer'])['coordinates']);
    final routePoints = <LatLng>[];
    for (final value in map(_route?['route'])['coordinates'] as List? ?? []) {
      if (value is List && value.length == 2) {
        final point = parseCoordinates({'latitude': value[1], 'longitude': value[0]});
        if (point != null) routePoints.add(point);
      }
    }
    final mapPoints = <LatLng>[if (restaurantPoint != null) LatLng(restaurantPoint.latitude, restaurantPoint.longitude), if (customerPoint != null) LatLng(customerPoint.latitude, customerPoint.longitude), ...routePoints];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order tracking'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tracking',
          ),
        ],
      ),
      body: order == null && _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  SelectableText('Order reference: ${widget.orderId}'),
                  if (_error != null) ...[
                    Text(
                      '${order == null ? '' : 'Showing last loaded status. '}$_error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _load,
                      child: const Text('Retry'),
                    ),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 16),
                    OrderStatusSurface(status: status, child: OrderStatusChip(status, text: status.replaceAll('_', ' ').toUpperCase())),
                    if (_updated != null)
                      Text(
                        'Updated: ${_updated!.toLocal().toString().split('.').first} • Refreshes every 7 seconds',
                      ),
                    if (terminal)
                      const Text(
                        'This order has ended. Remaining delivery steps will not continue.',
                      ),
                    const SizedBox(height: 16),
                    ...trackingSteps.map((step) {
                      final raw =
                          order[step.$3] ??
                          (step.$1 == 'placed' ? order['createdAt'] : null);
                      final date = raw is String
                          ? DateTime.tryParse(raw)?.toLocal()
                          : null;
                      final current = !terminal && status == step.$1;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          current
                              ? Icons.radio_button_checked
                              : date != null
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: current || date != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text('${step.$2}${current ? ' — Current' : ''}'),
                        subtitle: Text(
                          date != null
                              ? date.toString().split('.').first
                              : current
                              ? 'Timestamp unavailable'
                              : terminal
                              ? 'Not completed'
                              : 'Awaiting update',
                        ),
                      );
                    }),
                    const Divider(),
                    Text('Delivery address: ${order['deliveryAddress'] ?? ''}'),
                    Text(
                      'Rider: ${rider is Map
                          ? rider['name'] ?? 'Assigned rider'
                          : rider == null
                          ? 'Awaiting assignment'
                          : 'Assigned rider'}',
                    ),
                    if (rider is Map && rider['phone'] != null)
                      SelectableText('Phone: ${rider['phone']}'),
                    if (mapPoints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(mapPoints),
                              padding: const EdgeInsets.all(36),
                              maxZoom: 16,
                            ),
                          ),
                          children: [
                            TileLayer(urlTemplate: MapConfig.tileUrl, userAgentPackageName: MapConfig.userAgent, maxNativeZoom: 19),
                            if (routePoints.length > 1) PolylineLayer(polylines: [Polyline(points: routePoints, color: Colors.blue, strokeWidth: 5)]),
                            MarkerLayer(markers: [
                              if (restaurantPoint != null) Marker(point: LatLng(restaurantPoint.latitude, restaurantPoint.longitude), width: 44, height: 44, child: const Icon(Icons.store, color: Colors.orange)),
                              if (customerPoint != null) Marker(point: LatLng(customerPoint.latitude, customerPoint.longitude), width: 44, height: 44, child: const Icon(Icons.location_pin, color: Colors.blue)),
                            ]),
                            const SimpleAttributionWidget(source: Text(MapConfig.attribution)),
                          ],
                        ),
                      ),
                      Text('Distance: ${map(_route?['route'])['distanceMeters'] is num ? '${(map(_route?['route'])['distanceMeters'] / 1000).toStringAsFixed(1)} km' : 'Unavailable'}'),
                      Text('ETA: ${map(_route?['route'])['durationSeconds'] is num ? '${(map(_route?['route'])['durationSeconds'] / 60).ceil()} min' : 'Unavailable'}'),
                    ],
                    Text('Payment: ${order['paymentStatus'] ?? 'Unknown'}'),
                    Text('Total: LKR ${order['totalAmount'] ?? 0}'),
                  ],
                ],
              ),
            ),
    );
  }
}
