import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/widgets/location_picker.dart';
import 'package:latlong2/latlong.dart';

class MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  testWidgets('viewport is never selected until user taps and confirms', (
    tester,
  ) async {
    LatLng? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationPicker(tileProvider: MemoryTiles()),
                  ),
                );
              },
              child: const Text('Open map'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byIcon(Icons.location_pin), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    expect(
      find.text('Location selected. Confirm the marker matches your address.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('Selected:'), findsNothing);
    expect(result, isNull);
    await tester.tap(find.text('Confirm Delivery Location'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.latitude.abs(), lessThanOrEqualTo(90));
    expect(result!.longitude.abs(), lessThanOrEqualTo(180));
  });
}
