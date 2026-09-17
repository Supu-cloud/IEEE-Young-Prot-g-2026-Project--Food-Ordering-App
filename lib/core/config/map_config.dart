import 'package:latlong2/latlong.dart';

class MapConfig {
  static const tileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const attribution = '© OpenStreetMap contributors';
  static const attributionUrl = 'https://www.openstreetmap.org/copyright';
  static const userAgent = 'com.example.food_ordering_app';
  static Uri navigationUrl(LatLng point) =>
      Uri.https('www.openstreetmap.org', '/directions', {
        'engine': 'fossgis_osrm_car',
        'route': ';${point.latitude},${point.longitude}',
      });
}

LatLng? parseCoordinates(dynamic value) {
  if (value is! Map) return null;
  final lat = value['latitude'];
  final lng = value['longitude'];
  if (lat is! num ||
      lng is! num ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat.abs() > 90 ||
      lng.abs() > 180) {
    return null;
  }
  return LatLng(lat.toDouble(), lng.toDouble());
}

Map<String, double>? coordinateInput(String latitude, String longitude) {
  if (latitude.trim().isEmpty && longitude.trim().isEmpty) return null;
  final point = parseCoordinates({
    'latitude': double.tryParse(latitude),
    'longitude': double.tryParse(longitude),
  });
  if (point == null) {
    throw const FormatException(
      'Enter valid latitude (-90 to 90) and longitude (-180 to 180) together.',
    );
  }
  return {'latitude': point.latitude, 'longitude': point.longitude};
}
