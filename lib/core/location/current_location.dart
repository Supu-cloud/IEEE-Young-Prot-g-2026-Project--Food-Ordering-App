import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../network/api_exception.dart';

class LocationServicesDisabledException extends ApiException {
  const LocationServicesDisabledException()
    : super('Location services are turned off.');
}

class LocationPermissionDeniedForeverException extends ApiException {
  const LocationPermissionDeniedForeverException()
    : super('Location permission is permanently denied.');
}

class LocationPermissionDeniedException extends ApiException {
  const LocationPermissionDeniedException()
    : super('Location permission was denied.');
}

Future<LatLng> currentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationServicesDisabledException();
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionDeniedForeverException();
  }
  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    throw const LocationPermissionDeniedException();
  }
  try {
    final value = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return LatLng(value.latitude, value.longitude);
  } on TimeoutException {
    throw const ApiException('Location request timed out. Please retry.');
  }
}
