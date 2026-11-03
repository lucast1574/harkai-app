import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, debugPrint;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/navigation/app_shell.dart';
import 'package:harkai/features/reports/create_report.dart';

class StoreGps extends GeolocatorPlatform {
  Position get point => Position(
    latitude: -12.0464,
    longitude: -77.0428,
    timestamp: DateTime.now(),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => point;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => point;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      const Stream.empty();
}

const categories = [
  Category('pet', 'Mascotas', false, []),
  Category('event', 'Eventos', false, []),
  Category('fire', 'Incendio', true, []),
  Category('crash', 'Accidente', true, []),
  Category('theft', 'Robo', true, []),
];
Map<String, dynamic> report(
  String id,
  String type,
  String description,
  int age, {
  bool verified = false,
}) => {
  'id': id,
  'type': type,
  'description': description,
  'status': 'active',
  'latitude': -12.0464 + (age - 20) * 0.00012,
  'longitude': -77.0428 + (age - 20) * 0.00016,
  'verified': verified,
  'created_at': DateTime.now()
      .subtract(Duration(minutes: age))
      .toUtc()
      .toIso8601String(),
  'district': 'Cercado de Lima',
  'city': 'Lima',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'capture real Harkai screens for App Store compositions',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final oldGps = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = StoreGps();
      addTearDown(() => GeolocatorPlatform.instance = oldGps);
      final oldHttp = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = oldHttp);
      await tester.runAsync(() async {
        BuiltInMapCachingProvider.getOrCreateInstance(
          cacheDirectory: Directory(
            '.release-work/store-map-cache',
          ).absolute.path,
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const ipad = bool.fromEnvironment('STORE_IPAD');
      tester.view.physicalSize = ipad
          ? const Size(2064, 2752)
          : const Size(1206, 2622);
      tester.view.devicePixelRatio = ipad ? 2 : 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                'C:/flutter/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                'C:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
      for (final family in [
        'Ahem',
        '.SF UI Text',
        '.SF UI Display',
        '.SF Pro Text',
        '.SF Pro Display',
      ]) {
        final f = FontLoader(family)
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  'C:/flutter/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await f.load();
      }
      final reports = [
        report(
          'pet-1',
          'pet',
          'Perrita encontrada cerca del parque. Tiene collar azul.',
          8,
        ),
        report(
          'event-1',
          'event',
          'Jornada vecinal de limpieza del parque este sábado.',
          20,
          verified: true,
        ),
        report(
          'pet-2',
          'pet',
          'Buscamos a nuestro gato gris. Fue visto cerca del parque.',
          32,
        ),
      ];
      final api = ApiClient(
        transport: MockClient((r) async {
          final path = r.url.path;
          Object result = {'items': []};
          if (path.contains('incidents') || path.endsWith('/alerts')) {
            final type = r.url.queryParameters['type'];
            result = {
              'items': type == null
                  ? reports
                  : reports.where((p) => p['type'] == type).toList(),
              'next_cursor': null,
            };
          }
          if (path.contains('/geo/district')) {
            result = {
              'district': {'name': 'Cercado de Lima', 'province': 'Lima'},
            };
          }
          if (path.contains('/support/coverage')) result = {'covered': true};
          if (path.contains('/support/places')) {
            result = {
              'items': [
                {
                  'id': 'demo-health',
                  'name': 'Centro de salud vecinal',
                  'kind': 'health_center',
                  'address': 'Avenida del Parque 120',
                  'district': 'Lima',
                  'source_url': '',
                  'location_source_url': '',
                  'reviewed_at': '2026-11-02',
                  'latitude': -12.05,
                  'longitude': -77.04,
                },
                {
                  'id': 'demo-police',
                  'name': 'Comisaría del distrito',
                  'kind': 'police',
                  'address': 'Calle de la Comunidad 240',
                  'district': 'Lima',
                  'source_url': '',
                  'location_source_url': '',
                  'reviewed_at': '2026-11-02',
                  'latitude': -12.051,
                  'longitude': -77.041,
                },
                {
                  'id': 'demo-fire',
                  'name': 'Compañía de bomberos',
                  'kind': 'fire_station',
                  'address': 'Avenida Central 380',
                  'district': 'Lima',
                  'source_url': '',
                  'location_source_url': '',
                  'reviewed_at': '2026-11-02',
                  'latitude': -12.052,
                  'longitude': -77.042,
                },
              ],
            };
          }
          return http.Response(
            jsonEncode(result),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final app = AppController(api)
        ..loading = false
        ..categories = categories
        ..account = const Account(
          'demo',
          'Vecina de Harkai',
          'demo@example.invalid',
          'citizen',
          Preferences(),
        );
      final key = GlobalKey();
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 15));
          });
        }
      }

      Future<void> capture(String name) async {
        await settle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: ipad ? 2 : 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'store/appstore/source/${ipad ? 'ipad/' : ''}$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        debugPrint('CAPTURED $name');
      }

      Widget wrap(Widget child) => AppScope(
        controller: app,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(Brightness.light).copyWith(
            platform: TargetPlatform.iOS,
            filledButtonTheme: FilledButtonThemeData(
              style: appTheme(Brightness.light).filledButtonTheme.style!
                  .copyWith(
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: appTheme(Brightness.light).outlinedButtonTheme.style!
                  .copyWith(
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
            ),
          ),
          home: RepaintBoundary(key: key, child: child),
        ),
      );
      await tester.pumpWidget(wrap(const AppShell()));
      await settle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await settle();
      await capture('01-mapa');
      await tester.tap(find.text('Comunidad').last);
      await settle();
      await capture('02-comunidad');
      await tester.tap(find.byTooltip('Explorar'));
      await settle();
      await tester.tap(find.text('Mascotas').last);
      await settle();
      await capture('04-mascotas');
      await tester.tap(find.byTooltip('Explorar'));
      await settle();
      await tester.tap(find.text('Lugares de ayuda').first);
      await settle();
      await capture('05-ayuda');
      await tester.pumpWidget(wrap(const CreateReport(initialType: 'pet')));
      await settle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(
          fields.first,
          'Encontré una perrita con collar azul cerca del parque. Está acompañada y a salvo.',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }
      await capture('03-reportar');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 40));
      debugDefaultTargetPlatformOverride = null;
      await tester.runAsync(() async {
        await BuiltInMapCachingProvider.getOrCreateInstance().destroy();
      });
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('CAPTURE_STORE_ARTWORK'),
  );
}
