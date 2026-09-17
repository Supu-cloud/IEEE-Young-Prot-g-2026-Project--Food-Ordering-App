import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/map_config.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key, this.initial, this.tileProvider});
  final LatLng? initial;
  final TileProvider? tileProvider;
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late LatLng? selected = widget.initial;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select exact location')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Pan and zoom, then tap the exact location. The initial map view is not a selected location.',
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: selected ?? const LatLng(7.8, 80.7),
              initialZoom: selected == null ? 7 : 16,
              onTap: (_, point) => setState(
                () => selected = LatLng(
                  point.latitude,
                  ((point.longitude + 180) % 360) - 180,
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgent,
                tileProvider: widget.tileProvider,
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              const SimpleAttributionWidget(
                source: Text(MapConfig.attribution),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  selected == null
                      ? 'No location selected.'
                      : 'Location selected. Confirm the marker matches your address.',
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text('Confirm Delivery Location'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
