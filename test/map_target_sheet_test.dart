import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/map/map_target.dart';
import 'package:harkai/features/map/map_target_sheet.dart';
import 'package:harkai/features/reports/report_detail.dart';
import 'package:harkai/features/business/business_point.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('map sheet expands into the full report and its conversation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = <String, dynamic>{
      'id': '0123456789abcdef01234567',
      'type': 'violence',
      'description': 'Reporte de prueba en la avenida',
      'status': 'active',
      'latitude': -12.04,
      'longitude': -77.04,
      'verified': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    final app = AppController(
      ApiClient(
        transport: MockClient(
          (r) async => http.Response(
            jsonEncode(r.url.path.endsWith('/comments') ? {'items': []} : data),
            200,
          ),
        ),
      ),
    );
    bool closed = false;
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: appTheme(Brightness.dark),
          home: Scaffold(
            body: MapTargetSheet(
              target: MapTarget.report(Incident.fromJson(data)),
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getSize(find.byType(ReportDetail)).height;
    await tester.drag(find.text('Reporte en el mapa'), const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ReportDetail)).height,
      greaterThan(before + 200),
    );
    await tester.scrollUntilVisible(
      find.text('La conversación de este reporte'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('La conversación de este reporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byTooltip('Cerrar ficha'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Cerrar ficha'));
    expect(closed, isTrue);
  });
  testWidgets('promoted point sheet contains its offer and discount code', (
    tester,
  ) async {
    final app = AppController(ApiClient());
    final p = BusinessPoint({
      'id': '0123456789abcdef01234567',
      'name': 'Restaurante de prueba',
      'kind': 'restaurant',
      'description': 'Menú del barrio',
      'latitude': -12.04,
      'longitude': -77.04,
      'offer': 'Descuento en el menú del día',
      'discount_code': 'VECINO10',
    });
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          home: Scaffold(
            body: MapTargetSheet(target: MapTarget.business(p), onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Lugar promocionado'), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('VECINO10'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Descuento en el menú del día'), findsOneWidget);
    expect(find.text('VECINO10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
