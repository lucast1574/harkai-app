import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/help/support_directory.dart';
import 'package:harkai/features/help/support_directory_results.dart';
import 'package:harkai/features/help/support_place.dart';
import 'package:harkai/features/map/community_map.dart';
import 'package:harkai/features/map/map_target.dart';

class DirectoryGps extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: -12.07,
    longitude: -77.06,
    timestamp: DateTime.now(),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

SupportPlace place(
  String id,
  double latitude, {
  String kind = 'health_center',
  String district = 'Jesús María',
}) => SupportPlace(
  id: id,
  name: id,
  kind: kind,
  address: 'Dirección del centro',
  district: district,
  source: '',
  locationSource: '',
  reviewed: '2026-11-04',
  latitude: latitude,
  longitude: -77.06,
);

void main() {
  final places = [
    place('Centro vecino', -12.073, district: 'Pueblo Libre'),
    place('Comisaría cercana', -12.071, kind: 'police'),
    place('Centro lejano', -12.10),
  ];
  test(
    'support radius crosses district boundaries, sorts distances and filters kinds',
    () {
      final results = supportDirectoryResults(
        places,
        const LatLng(-12.07, -77.06),
      );
      expect(results.map((p) => p.place.id), [
        'Comisaría cercana',
        'Centro vecino',
      ]);
      expect(
        supportDirectoryResults(
          places,
          const LatLng(-12.07, -77.06),
          kind: 'health',
        ).single.place.id,
        'Centro vecino',
      );
      expect(
        supportDirectoryResults(
          places,
          const LatLng(-12.07, -77.06),
          search: 'Pueblo Libre',
        ).single.place.id,
        'Centro vecino',
      );
    },
  );
  testWidgets(
    'photo directory has no map and opens the selected place on the main map',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final oldGps = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = DirectoryGps();
      addTearDown(() => GeolocatorPlatform.instance = oldGps);
      final radii = <String?>[];
      MapTarget? selected;
      final app = AppController(
        ApiClient(
          transport: MockClient((r) async {
            radii.add(r.url.queryParameters['radius_meters']);
            expect(r.url.queryParameters.containsKey('ubigeo'), false);
            return http.Response(
              jsonEncode({'items': places.map((p) => p.toJson()).toList()}),
              200,
              headers: {"content-type": "application/json; charset=utf-8"},
            );
          }),
        ),
      );
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: appTheme(Brightness.dark),
            home: Scaffold(body: SupportDirectory(onMap: (p) => selected = p)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(radii.last, '2000');
      expect(find.byType(CommunityMap), findsNothing);
      expect(find.text('Centro lejano'), findsNothing);
      await tester.tap(find.text('Centro vecino'));
      expect(selected!.support!.id, 'Centro vecino');
      await tester.tap(find.text('2 km a la redonda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 km a la redonda'));
      await tester.pumpAndSettle();
      expect(radii.last, '5000');
      expect(find.text('Centro lejano'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Comisaría');
      await tester.pumpAndSettle();
      expect(find.text('Centro vecino'), findsNothing);
      expect(find.text('Comisaría cercana'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
