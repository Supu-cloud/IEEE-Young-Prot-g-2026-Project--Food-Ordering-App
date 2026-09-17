import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_ordering_app/core/config/map_config.dart';
import 'package:food_ordering_app/core/location/current_location.dart';
import 'package:food_ordering_app/features/operations/data/operations_repository.dart';
import 'package:food_ordering_app/features/rider/presentation/rider_map_screen.dart';

// All fixture coordinates and tiles are test-only. No live backend or tiles are requested.
class MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

class FakeRoutes extends OperationsRepository {
  FakeRoutes(this.response) : super(Dio());
  final Map<String, dynamic> response;
  int requests = 0;
  @override
  Future<Map<String, dynamic>> deliveryRoute(String id) async {
    requests++;
    return response;
  }
}

class FakeLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requested = LocationPermission.denied;
  int positionRequests = 0;
  int permissionRequests = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    return Position(
      latitude: 6.85,
      longitude: 79.85,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

Map<String, dynamic> fixture() => {
  'orderId': 'test-order',
  'status': 'picked_up',
  'restaurant': {
    'name': 'Pickup',
    'address': 'Pickup address',
    'coordinates': {'latitude': 6.9, 'longitude': 79.8},
  },
  'customer': {
    'name': 'Customer',
    'address': 'Delivery address',
    'coordinates': {'latitude': 6.8, 'longitude': 79.9},
  },
  'route': {
    'distanceMeters': 1200,
    'durationSeconds': 300,
    'coordinates': [
      [79.8, 6.9],
      [79.85, 6.85],
      [79.9, 6.8],
    ],
  },
  'errors': <Map<String, dynamic>>[],
};
void main() {
  final original = GeolocatorPlatform.instance;
  late FakeLocation location;
  setUp(() => GeolocatorPlatform.instance = location = FakeLocation());
  tearDown(() => GeolocatorPlatform.instance = original);
  test(
    'coordinate validation accepts zero and rejects incomplete or nonfinite coordinates',
    () {
      expect(coordinateInput('0', '0'), {'latitude': 0.0, 'longitude': 0.0});
      expect(coordinateInput('', ''), isNull);
      for (final pair in [
        ['91', '0'],
        ['0', '181'],
        ['NaN', '0'],
        ['1', ''],
      ]) {
        expect(() => coordinateInput(pair[0], pair[1]), throwsFormatException);
      }
    },
  );
  test('denied forever never prompts again or requests a position', () async {
    location.permission = LocationPermission.deniedForever;
    await expectLater(
      currentLocation(),
      throwsA(predicate((e) => e.toString().contains('app settings'))),
    );
    expect(location.permissionRequests, 0);
    expect(location.positionRequests, 0);
  });
  Future<void> show(
    WidgetTester tester,
    Map<String, dynamic> response, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: RiderMapScreen(
            repository: FakeRoutes(response),
            deliveryId: 'delivery',
            tileProvider: MemoryTiles(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'backend geometry, two markers, distance, ETA and attribution render without permission',
    (tester) async {
      await show(tester, fixture());
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      final line = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single;
      expect(line.points.first.latitude, 6.9);
      expect(line.points.first.longitude, 79.8);
      expect(find.text('Distance: 1.2 km'), findsOneWidget);
      expect(
        find.text('Estimated travel time: 5 min (no live traffic)'),
        findsOneWidget,
      );
      expect(find.text(MapConfig.attribution), findsOneWidget);
      expect(location.permissionRequests, 0);
      expect(location.positionRequests, 0);
    },
  );
  testWidgets('denied permission leaves both markers and route in dark theme', (
    tester,
  ) async {
    await show(tester, fixture(), brightness: Brightness.dark);
    await tester.ensureVisible(find.text('Show my location'));
    await tester.tap(find.text('Show my location'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Location permission was denied'),
      findsOneWidget,
    );
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
      2,
    );
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(location.positionRequests, 0);
  });
  testWidgets('granted permission adds rider marker and keeps route', (
    tester,
  ) async {
    location.requested = LocationPermission.whileInUse;
    await show(tester, fixture());
    await tester.ensureVisible(find.text('Show my location'));
    await tester.tap(find.text('Show my location'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
      3,
    );
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(location.positionRequests, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'provider outage still displays both markers and an explicit error',
    (tester) async {
      final response = fixture()
        ..['route'] = null
        ..['errors'] = [
          {'message': 'Routing service is temporarily unavailable.'},
        ];
      await show(tester, response);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      expect(find.byType(PolylineLayer), findsNothing);
      expect(
        find.text('Routing service is temporarily unavailable.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'missing destination preserves pickup and explains what is missing',
    (tester) async {
      final response = fixture()
        ..['route'] = null
        ..['errors'] = [
          {'message': 'Customer delivery coordinates are missing.'},
        ];
      response['customer'] = {
        ...(response['customer'] as Map),
        'coordinates': null,
      };
      await show(tester, response);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        1,
      );
      expect(
        find.text('Customer delivery coordinates are missing.'),
        findsOneWidget,
      );
      expect(find.text('Start Navigation'), findsNothing);
    },
  );
}
