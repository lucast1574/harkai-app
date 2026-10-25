import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:harkai/features/help/coverage_notice.dart';
import 'package:latlong2/latlong.dart';
import 'package:harkai/features/help/support_place.dart';
import 'package:harkai/features/help/support_proximity.dart';

SupportPlace place(String id, double latitude) => SupportPlace(
  id: id,
  name: 'Hospital $id',
  kind: 'hospital',
  address: 'Dirección',
  district: 'Trujillo',
  source: 'https://www.gob.pe',
  locationSource: 'https://www.gob.pe',
  reviewed: '2026-10-11',
  latitude: latitude,
  longitude: -79.0287,
);
void main() {
  testWidgets(
    'Only an uncovered city gets the coverage message; failures stay distinct',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CoverageNotice(covered: false))),
      );
      expect(find.text('Ubicación fuera del directorio nacional'), findsOneWidget);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CoverageNotice(covered: true))),
      );
      expect(find.text('Ubicación fuera del directorio nacional'), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CoverageNotice(error: 'unavailable')),
        ),
      );
      expect(find.text('No pudimos comprobar la cobertura'), findsOneWidget);
      expect(find.text('Ubicación fuera del directorio nacional'), findsNothing);
    },
  );
  test('Health proximity uses real GPS, nearest first, within 500 meters', () {
    final near = place('near', -8.1117);
    final farther = place('farther', -8.1136);
    final distant = place('distant', -8.1316);
    final results = nearbySupport(
      [distant, farther, near],
      const LatLng(-8.1116, -79.0287),
      accuracy: 20,
    );
    expect(results.map((r) => r.place.id), ['near', 'farther']);
    expect(results.first.meters, lessThan(20));
    expect(nearbySupport([near], const LatLng(-12.0464, -77.0428)), isEmpty);
  });
  test('An imprecise location never triggers a nearby health claim', () {
    expect(
      nearbySupport(
        [place('near', -8.1116)],
        const LatLng(-8.1116, -79.0287),
        accuracy: 500,
      ),
      isEmpty,
    );
    expect(
      nearbySupport(
        [place('near', -8.1116)],
        const LatLng(-8.1116, -79.0287),
        accuracy: double.nan,
      ),
      isEmpty,
    );
  });
  test('Notification payload roundtrip preserves the permanent place', () {
    final original = place('renipress-00005195', -8.11466301);
    final restored = SupportPlace.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.latitude, original.latitude);
    expect(restored.source, original.source);
  });
}
