import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/community/report_comments.dart';
import 'quick_report_sheet_test.dart' show captureForm;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('comments send beside input and dismiss keyboard: $brightness', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      const capture = bool.fromEnvironment('CAPTURE_COMMENT_REVIEW');
      final boundary = GlobalKey();
      if (capture) {
        for (final family in ['Roboto', 'Ahem', 'MaterialIcons']) {
          final font = family == 'MaterialIcons'
              ? 'MaterialIcons-Regular.otf'
              : 'roboto-regular.ttf';
          await (FontLoader(family)..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      'C:/flutter/flutter/bin/cache/artifacts/material_fonts/$font',
                    ).readAsBytesSync(),
                  ),
                ),
              ))
              .load();
        }
      }
      var writes = 0;
      var response = Completer<http.Response>();
      final app =
          AppController(
              ApiClient(
                transport: MockClient((request) async {
                  expect(request.url.path, '/v1/incidents/report/comments');
                  if (request.method == 'POST') {
                    writes++;
                    expect(jsonDecode(request.body), {
                      'body': 'Lo apagaron a tiempo',
                    });
                    return response.future;
                  }
                  return http.Response('{"items":[]}', 200);
                }),
              ),
            )
            ..account = const Account(
              'user',
              'Nombre privado',
              'private@example.test',
              'user',
              Preferences(),
            );
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: appTheme(brightness),
            home: Scaffold(
              body: RepaintBoundary(
                key: boundary,
                child: Material(
                  color: appTheme(brightness).scaffoldBackgroundColor,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(20),
                    children: const [ReportComments(incidentId: 'report')],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextFormField);
      final send = find.widgetWithIcon(IconButton, Icons.send_rounded);
      expect(tester.widget<IconButton>(send).onPressed, isNull);
      await tester.enterText(field, 'Lo apagaron a tiempo');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(send).left,
        greaterThan(tester.getRect(field).right),
      );
      expect(
        tester.getRect(send).center.dy,
        inInclusiveRange(
          tester.getRect(field).top,
          tester.getRect(field).bottom,
        ),
      );
      expect(tester.getRect(send).bottom, lessThanOrEqualTo(544));
      if (capture) {
        await captureForm(tester, boundary, 'comments-${brightness.name}');
      }
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('Lo apagaron a tiempo'), findsOneWidget);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Aporta contexto, pregunta o comparte una actualización.'),
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(send);
      await tester.pump();
      expect(writes, 1);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Publicando…',
              ),
            )
            .onPressed,
        isNull,
      );
      response.complete(http.Response('{"error":{"code":"unavailable"}}', 503));
      await tester.pumpAndSettle();
      expect(find.text('Lo apagaron a tiempo'), findsOneWidget);
      response = Completer<http.Response>();
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      response.complete(
        http.Response(
          jsonEncode({
            'id': 'comment',
            'body': 'Lo apagaron a tiempo',
            'author_name': 'Vecino anónimo',
            'created_at': '2026-11-09T22:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
      expect(find.text('Lo apagaron a tiempo'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: appTheme(brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [ReportComments(incidentId: 'report')],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        field,
        'Comentario largo\ncon varias\nlíneas de texto',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
