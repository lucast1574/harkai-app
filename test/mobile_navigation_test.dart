import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/navigation/app_shell.dart';
import 'package:harkai/features/map/community_map.dart';
import 'package:harkai/features/map/map_target.dart';
import 'package:harkai/features/map/map_target_sheet.dart';
import 'package:harkai/features/community/district_chat.dart';
import 'package:harkai/features/help/support_directory.dart';
import 'package:harkai/features/help/support_place.dart';
import 'package:harkai/features/pets/pets_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Android back returns to map and root stays open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      ApiClient(
        transport: MockClient(
          (_) async => http.Response(
            jsonEncode({'items': [], 'categories': [], 'capabilities': {}}),
            200,
          ),
        ),
      ),
    );
    controller.loading = false;
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: appTheme(Brightness.dark),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Alertas'), findsNothing);
    expect(find.text('Negocios'), findsOneWidget);
    expect(find.text('Chat'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mascotas'),
      ),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Cuenta'), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(4),
    );
    await tester.tap(find.text('Comunidad').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CommunityMap), findsNothing);
    expect(find.byType(DistrictChat), findsOneWidget);
    expect(find.text('Chat del distrito'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CommunityMap), findsOneWidget);
    await tester.tap(find.text('Mascotas').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PetsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    final helpButton = find.byTooltip('Centros de ayuda cercanos');
    final helpStyle = tester
        .widget<IconButton>(
          find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'Centros de ayuda cercanos',
          ),
        )
        .style!;
    expect(helpStyle.fixedSize!.resolve({}), const Size(40, 40));
    await tester.tap(helpButton);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SupportDirectory), findsOneWidget);
    expect(find.byType(CommunityMap), findsNothing);
    const place = SupportPlace(
      id: 'test-center',
      name: 'Centro vecino',
      kind: 'health_center',
      address: 'Dirección',
      district: 'Jesús María',
      source: '',
      locationSource: '',
      reviewed: '',
      latitude: -12.04,
      longitude: -77.04,
    );
    tester
        .widget<SupportDirectory>(find.byType(SupportDirectory))
        .onMap(MapTarget.place(place));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MapTargetSheet), findsOneWidget);
    expect(
      tester
          .widget<CommunityMap>(find.byType(CommunityMap))
          .supportPlaces
          .any((p) => p.id == place.id),
      true,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AppShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'a directory destination draws a reference line on the primary map',
    (tester) async {
      const user = LatLng(-12.04, -77.04), target = LatLng(-12.041, -77.041);
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 700,
            child: CommunityMap(
              center: user,
              userPosition: user,
              target: target,
              initialZoom: 16,
            ),
          ),
        ),
      );
      await tester.pump();
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines.single.points, [user, target]);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('background tap deselects while marker tap selects the point', (
    tester,
  ) async {
    int selected = 0, cleared = 0;
    final incident = Incident(
      id: '0123456789abcdef01234567',
      type: 'fire',
      description: 'Prueba',
      status: 'active',
      latitude: -12.04,
      longitude: -77.04,
      verified: false,
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityMap(
            center: const LatLng(-12.04, -77.04),
            incidents: [incident],
            onReport: (_) => selected++,
            onBackgroundTap: () => cleared++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Incendio · No verificado'));
    await tester.pump();
    expect(selected, 1);
    expect(cleared, 0);
    await tester.tapAt(const Offset(30, 100));
    await tester.pump(const Duration(milliseconds: 350));
    expect(cleared, 1);
    await tester.pumpWidget(const SizedBox());
  });
  test('dark sheets and focused inputs stay in the navy palette', () {
    final theme = appTheme(Brightness.dark);
    expect(theme.bottomSheetTheme.backgroundColor, theme.colorScheme.surface);
    expect(theme.colorScheme.surfaceContainerLow, theme.colorScheme.surface);
    expect(
      theme.inputDecorationTheme.focusedBorder!.borderSide,
      BorderSide.none,
    );
  });
  testWidgets('initial GPS focus is applied when the map first becomes ready', (
    tester,
  ) async {
    const point = LatLng(-12.0464, -77.0428);
    await tester.pumpWidget(
      const MaterialApp(
        home: CommunityMap(center: point, userPosition: point, focusRequest: 1),
      ),
    );
    await tester.pump();
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    expect(camera.zoom, 16.5);
    expect(camera.center.latitude, closeTo(point.latitude, .00001));
    expect(camera.center.longitude, closeTo(point.longitude, .00001));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('location focus zooms above the expanded reporting panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const point = LatLng(-12.0464, -77.0428);
    Widget map(int request) => MaterialApp(
      home: CommunityMap(
        center: point,
        userPosition: point,
        focusRequest: request,
        bottomObstruction: 350,
        topObstruction: 130,
      ),
    );
    await tester.pumpWidget(map(0));
    await tester.pump();
    await tester.pumpWidget(map(1));
    await tester.pump();
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    expect(camera.zoom, 16.5);
    expect(camera.latLngToScreenOffset(point).dy, closeTo(290, 1));
    await tester.pumpWidget(const SizedBox());
  });
}
