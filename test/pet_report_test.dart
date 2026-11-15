import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/reports/quick_report_sheet.dart';
import 'package:harkai/features/reports/report_contact_field.dart';
import 'quick_report_sheet_test.dart' show location, captureForm;

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_REPORT_REVIEW')) {
      for (final family in ['Roboto', 'Ahem', 'MaterialIcons']) {
        final file = family == 'MaterialIcons'
            ? 'MaterialIcons-Regular.otf'
            : 'roboto-regular.ttf';
        await (FontLoader(family)..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    'C:/flutter/flutter/bin/cache/artifacts/material_fonts/$file',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load();
      }
    }
  });
  test('phone validation accepts formatting and rejects invalid contacts', () {
    for (final value in [
      '',
      '123',
      'abcdefghi',
      '987+654321',
      '1234567890123456',
    ]) {
      expect(reportContactValidator(value), isNotNull, reason: value);
    }
    for (final value in ['987 654 321', '+51 (987) 654-321']) {
      expect(reportContactValidator(value), isNull, reason: value);
    }
    expect(normalizedReportContact('+51 (987) 654-321'), '+51987654321');
  });

  for (final share in [false, true]) {
    testWidgets('pets publish with explicit type and contact sharing=$share', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final payloads = <Map<String, dynamic>>[];
      var analyses = 0;
      final api = ApiClient(
        transport: MockClient((request) async {
          if (request.url.path.endsWith('analysis/text')) {
            analyses++;
            return http.Response('{}', 503);
          }
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          payloads.add(payload);
          return http.Response(
            jsonEncode({
              ...payload,
              'id': 'pet-report',
              'type': 'pet',
              'status': 'active',
              'verified': false,
              'created_at': '2026-11-14T12:00:00Z',
            }),
            201,
          );
        }),
      );
      final app = AppController(api)
        ..categories = const [
          Category('pet', 'Mascota perdida o encontrada', false, []),
        ];
      addTearDown(app.dispose);
      final boundary = GlobalKey();
      final theme = appTheme(share ? Brightness.dark : Brightness.light);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: const bool.fromEnvironment('CAPTURE_REPORT_REVIEW')
                ? theme.copyWith(
                    filledButtonTheme: const FilledButtonThemeData(
                      style: ButtonStyle(
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                : theme,
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: QuickReportSheet(category: 'pet', getLocation: location),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Busco a Luna, lleva collar rojo.',
      );
      await tester.pump(const Duration(milliseconds: 1200));
      expect(analyses, 0);
      expect(find.text('Mascota perdida o encontrada'), findsOneWidget);
      expect(find.text('Teléfono de contacto'), findsNothing);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final phone = find.byType(TextFormField).last;
      await tester.enterText(phone, 'abc');
      await tester.ensureVisible(find.text('Publicar reporte'));
      await tester.tap(find.text('Publicar reporte'));
      await tester.pumpAndSettle();
      expect(payloads, isEmpty);
      await tester.enterText(phone, '+51 (987) 654-321');
      if (!share) {
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(find.text('Publicar reporte'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_REPORT_REVIEW')) {
        await captureForm(tester, boundary, 'pet-contact-$share');
      }
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Publicar reporte'));
      await tester.tap(find.text('Publicar reporte'));
      await tester.pumpAndSettle();
      expect(payloads, hasLength(1));
      expect(payloads.single['type'], 'pet');
      expect(payloads.single['manual_type'], true);
      expect(payloads.single['share_contact'], share);
      expect(payloads.single['contact_info'], share ? '+51987654321' : isNull);
      expect(analyses, 0);
    });
  }
}
