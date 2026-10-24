import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/navigation/app_shell.dart';
import 'package:harkai/features/map/community_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Android back returns to map and root stays open', (
    tester,
  ) async {
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
    expect(find.text('Ponte en el mapa'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Cuenta'), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(3),
    );
    await tester.tap(find.text('Comunidad').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CommunityMap), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CommunityMap), findsOneWidget);
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
