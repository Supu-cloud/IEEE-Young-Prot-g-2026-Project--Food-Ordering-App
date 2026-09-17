import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/map_config.dart';
import '../../../core/location/current_location.dart';
import '../../operations/data/operations_repository.dart';

class RiderMapScreen extends StatefulWidget {
  const RiderMapScreen({
    super.key,
    required this.repository,
    required this.deliveryId,
    this.tileProvider,
  });
  final TileProvider? tileProvider;
  final OperationsRepository repository;
  final String deliveryId;
  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  final controller = MapController();
  String? boundsSignature;
  Map<String, dynamic>? data;
  String? error;
  String? locationError;
  LatLng? rider;
  bool loading = true;
  bool locating = false;
  bool updating = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await widget.repository.deliveryRoute(widget.deliveryId);
      if (mounted) setState(() => data = value);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> locate() async {
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final point = await currentLocation();
      if (mounted) setState(() => rider = point);
    } catch (failure) {
      if (mounted) setState(() => locationError = failure.toString());
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> navigate(LatLng destination) async {
    try {
      // Android opens the installed navigation chooser; other platforms use OSM directions.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final uri = Uri.parse(
          'geo:${destination.latitude},${destination.longitude}?q=${destination.latitude},${destination.longitude}',
        );
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      }
      if (!await launchUrl(
        MapConfig.navigationUrl(destination),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('No navigation application is available.');
      }
    } catch (failure) {
      if (mounted) {
        setState(() => error = 'Unable to open navigation. $failure');
      }
    }
  }

  Marker marker(String label, LatLng point, Color color, IconData icon) =>
      Marker(
        point: point,
        width: 110,
        height: 65,
        child: Semantics(
          label: label,
          child: Column(
            children: [
              SizedBox(
                height: 25,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Icon(icon, color: color, size: 32),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final restaurant = map(data?['restaurant']);
    final customer = map(data?['customer']);
    final route = map(data?['route']);
    final pickup = parseCoordinates(restaurant['coordinates']);
    final destination = parseCoordinates(customer['coordinates']);
    final line = <LatLng>[];
    for (final value in route['coordinates'] as List? ?? []) {
      if (value is List && value.length == 2) {
        final point = parseCoordinates({
          'latitude': value[1],
          'longitude': value[0],
        });
        if (point != null) line.add(point);
      }
    }
    final points = [?pickup, ?destination, ?rider, ...line];
    final distance = route['distanceMeters'];
    final duration = route['durationSeconds'];
    final fit = points.isEmpty
        ? null
        : CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(55),
            maxZoom: 16,
          );
    final signature = points
        .map((p) => '${p.latitude},${p.longitude}')
        .join(';');
    if (signature != boundsSignature) {
      boundsSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && fit != null) controller.fitCamera(fit);
      });
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Rider Map', style: Theme.of(context).textTheme.headlineSmall),
        if (data != null)
          Text('Order #${data!['orderId']} • ${label(data!['status'])}'),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        for (final value in maps(data?['errors']))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${value['message']}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (maps(data?['errors']).any(
          (value) => value['code'] == 'RESTAURANT_LOCATION_MISSING' ||
              value['code'] == 'CUSTOMER_LOCATION_MISSING',
        ))
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'This delivery may have been created before map locations were saved. Update the restaurant location, select the customer delivery point, and create a fresh order; existing orders are never assigned guessed coordinates.',
            ),
          ),
        if (fit != null)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .48,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(initialCameraFit: fit, maxZoom: 19),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrl,
                  userAgentPackageName: MapConfig.userAgent,
                  maxNativeZoom: 19,
                  tileProvider: widget.tileProvider,
                ),
                if (line.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: line,
                        color: Colors.blue,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (pickup != null)
                      marker(
                        'Restaurant',
                        pickup,
                        Colors.orange.shade800,
                        Icons.store,
                      ),
                    if (destination != null)
                      marker(
                        'Customer',
                        destination,
                        Colors.blue,
                        Icons.location_pin,
                      ),
                    if (rider != null)
                      marker(
                        'Rider',
                        rider!,
                        Colors.green,
                        Icons.delivery_dining,
                      ),
                  ],
                ),
                SimpleAttributionWidget(
                  source: const Text(MapConfig.attribution),
                  onTap: () => launchUrl(
                    Uri.parse(MapConfig.attributionUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          )
        else if (!loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Map locations are not available for this delivery.'),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant: ${restaurant['name'] ?? 'Restaurant'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${restaurant['address'] ?? 'Pickup address unavailable.'}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Customer: ${customer['name'] ?? 'Customer'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${customer['address'] ?? 'Delivery address unavailable.'}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Distance: ${distance is num ? '${(distance / 1000).toStringAsFixed(1)} km' : 'Unavailable'}',
                ),
                Text(
                  'Estimated travel time: ${duration is num ? '${(duration / 60).ceil().clamp(1, 99999)} min (no live traffic)' : 'Unavailable'}',
                ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: locating ? null : locate,
              icon: const Icon(Icons.my_location),
              label: Text(
                locating
                    ? 'Finding location…'
                    : rider == null
                    ? 'Show my location'
                    : 'Refresh rider location',
              ),
            ),
            OutlinedButton(
              onPressed: loading ? null : load,
              child: const Text('Retry route'),
            ),
            if (pickup != null)
              OutlinedButton(
                onPressed: () => navigate(pickup),
                child: const Text('Navigate to Restaurant'),
              ),
            if (destination != null)
              FilledButton.icon(
                onPressed: () => navigate(destination),
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation'),
              ),
            if (data?['status'] == 'picked_up')
              FilledButton(
                onPressed: updating
                    ? null
                    : () async {
                        setState(() => updating = true);
                        try {
                          await widget.repository.deliveryStatus(
                            widget.deliveryId,
                            'out_for_delivery',
                          );
                          if (mounted) await load();
                        } catch (failure) {
                          if (mounted) {
                            setState(() => error = failure.toString());
                          }
                        } finally {
                          if (mounted) setState(() => updating = false);
                        }
                      },
                child: const Text('Start Delivery'),
              ),
          ],
        ),
        if (rider != null)
          const Text(
            'Rider position is the last requested location. Use Refresh to update it.',
          ),
        if (locationError != null) Text(locationError!),
      ],
    );
  }
}
