import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../location/current_location.dart';
import '../config/map_config.dart';
import 'location_picker.dart';
import 'package:latlong2/latlong.dart';

class CoordinateFields extends StatefulWidget {
  const CoordinateFields({
    super.key,
    required this.latitude,
    required this.longitude,
    this.enabled = true,
    required this.onChanged,
  });
  final String latitude;
  final String longitude;
  final bool enabled;
  final void Function(String latitude, String longitude) onChanged;
  @override
  State<CoordinateFields> createState() => _CoordinateFieldsState();
}

class _CoordinateFieldsState extends State<CoordinateFields> {
  late final lat = TextEditingController(text: widget.latitude);
  late final lng = TextEditingController(text: widget.longitude);
  bool busy = false;
  String? message;
  @override
  void didUpdateWidget(CoordinateFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != lat.text) lat.text = widget.latitude;
    if (widget.longitude != lng.text) lng.text = widget.longitude;
  }

  @override
  void dispose() {
    lat.dispose();
    lng.dispose();
    super.dispose();
  }

  Future<void> _settingsDialog({required bool appSettings}) async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appSettings
              ? 'Location permission required'
              : 'Location services are turned off.',
        ),
        content: Text(
          appSettings
              ? 'Allow location access in App Settings, then try again.'
              : 'Turn on GPS/location services to use your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              appSettings ? 'Open App Settings' : 'Open Location Settings',
            ),
          ),
        ],
      ),
    );
    if (open == true) {
      if (appSettings) {
        await Geolocator.openAppSettings();
      } else {
        await Geolocator.openLocationSettings();
      }
    }
  }

  Future<void> _openPicker(LatLng initial) async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPicker(initial: initial)),
    );
    if (!mounted || !widget.enabled || point == null) return;
    lat.text = point.latitude.toString();
    lng.text = point.longitude.toString();
    widget.onChanged(lat.text, lng.text);
    setState(
      () => message =
          'Location saved. Enter or confirm the address text before continuing.',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Select the exact location on the map. Use your location only when you are at this address.',
      ),
      TextButton.icon(
        icon: const Icon(Icons.my_location),
        label: Text(busy ? 'Finding location…' : 'Use my current location'),
        onPressed: !widget.enabled || busy
            ? null
            : () async {
                setState(() {
                  busy = true;
                  message = null;
                });
                try {
                  final point = await currentLocation();
                  if (!mounted || !widget.enabled) return;
                  await _openPicker(point);
                } catch (error) {
                  if (error is LocationServicesDisabledException) {
                    await _settingsDialog(appSettings: false);
                  } else if (error
                      is LocationPermissionDeniedForeverException) {
                    await _settingsDialog(appSettings: true);
                  } else if (mounted) {
                    setState(() => message = error.toString());
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
      ),
      TextButton.icon(
        icon: const Icon(Icons.map),
        label: const Text('Choose location on map'),
        onPressed: !widget.enabled || busy
            ? null
            : () async {
                await _openPicker(
                  parseCoordinates({
                        'latitude': double.tryParse(lat.text),
                        'longitude': double.tryParse(lng.text),
                      }) ??
                      const LatLng(7.8, 80.7),
                );
              },
      ),
      if (message != null) Text(message!),
    ],
  );
}
