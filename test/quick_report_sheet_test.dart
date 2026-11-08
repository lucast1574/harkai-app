import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/reports/quick_report_sheet.dart';

Future<Position> location() async => Position(
  latitude: -12,
  longitude: -77,
  timestamp: DateTime(2026),
  accuracy: 8,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets('report form adapts type and dismisses keyboard in $brightness', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      const recordChannel = MethodChannel('com.llfbandit.record/messages');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        recordChannel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          recordChannel,
          null,
        ),
      );
      const capture = bool.fromEnvironment('CAPTURE_REPORT_REVIEW');
      if (capture) {
        for (final family in ['Roboto', 'Ahem']) {
          await (FontLoader(family)..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      'C:/flutter/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
                    ).readAsBytesSync(),
                  ),
                ),
              ))
              .load();
        }
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    'C:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load();
      }
      final api = ApiClient(
        transport: MockClient((request) async {
          expect(jsonDecode(request.body), {'text': 'Incendio'});
          return http.Response(
            jsonEncode({
              'suggested_type': 'fire',
              'reason': 'Revisa el reporte',
              'advice': <String>[],
            }),
            200,
          );
        }),
      );
      final controller = AppController(api)
        ..capabilities = {'audio': true}
        ..categories = const [
          Category('fire', 'Incendio', true, []),
          Category('theft', 'Robo', true, []),
          Category('pet', 'Mascota perdida o encontrada', false, []),
          Category(
            'public_drinking',
            'Consumo de alcohol en vía pública',
            false,
            [],
          ),
        ];
      addTearDown(controller.dispose);
      final boundary = GlobalKey();
      final theme = appTheme(brightness);
      final previewTheme = capture
          ? theme.copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: theme.filledButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          : theme;
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            theme: previewTheme,
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: appTheme(brightness).colorScheme.surface,
                    child: QuickReportSheet(
                      category: 'crime',
                      getLocation: location,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = find.byType(TextFormField).first;
      final input = tester.widget<TextField>(find.byType(TextField).first);
      expect(input.decoration?.labelText, isNull);
      if (capture) {
        await captureForm(tester, boundary, '${brightness.name}-empty');
      }
      await tester.enterText(field, 'Incendio');
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('Reportar incendio'), findsOneWidget);
      expect(find.text('Incendio · automático'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (capture) {
        await captureForm(tester, boundary, '${brightness.name}-keyboard');
      }
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}

Future<void> captureForm(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('.dart_tool/report-review')
      ..createSync(recursive: true);
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
