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
import 'package:harkai/features/community/district_thread.dart';

const message = {
  'id': 'aaaaaaaaaaaaaaaaaaaaaaaa',
  'body': '¿Ya volvió el agua por la avenida Brasil?',
  'district': 'Jesús María',
  'created_at': '2026-11-04T19:12:00Z',
};
Map<String, dynamic> reply(String id, String body) => {
  'id': id.padLeft(24, '0'),
  'body': body,
  'author_name': 'Vecino anónimo',
  'created_at': '2026-11-04T19:16:00Z',
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final authenticated in [true, false]) {
    testWidgets(
      'thread is isolated, preserves failed drafts and paginated replies, auth=$authenticated',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool failSend = true;
        int writes = 0;
        final app = AppController(
          ApiClient(
            transport: MockClient((r) async {
              expect(r.url.path, '/v1/forum/aaaaaaaaaaaaaaaaaaaaaaaa/comments');
              if (r.method == 'POST') {
                writes++;
                expect(jsonDecode(r.body), {'body': 'Gracias por avisar'});
                return http.Response(
                  jsonEncode(
                    failSend
                        ? {
                            'error': {'code': 'unavailable'},
                          }
                        : reply('3', 'Gracias por avisar'),
                  ),
                  failSend ? 503 : 201,
                  headers: {"content-type": "application/json; charset=utf-8"},
                );
              }
              return http.Response(
                jsonEncode(
                  r.url.queryParameters.containsKey('cursor')
                      ? {
                          'items': [reply('2', 'Por mi cuadra todavía no.')],
                        }
                      : {
                          'items': [reply('1', 'Ya volvió por aquí.')],
                          'next_cursor': '1'.padLeft(24, '0'),
                        },
                ),
                200,
                headers: {"content-type": "application/json; charset=utf-8"},
              );
            }),
          ),
        );
        if (authenticated) {
          app.account = const Account(
            'user',
            'Nombre privado',
            'private@example.test',
            'user',
            Preferences(),
          );
        }
        await tester.pumpWidget(
          AppScope(
            controller: app,
            child: MaterialApp(
              theme: appTheme(Brightness.dark),
              home: const DistrictThread(message: message),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mensaje original'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Nombre privado'), findsNothing);
        if (!authenticated) {
          expect(find.text('Ingresar para responder'), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(writes, 0);
        } else {
          await tester.tap(find.text('Ver más respuestas'));
          await tester.pumpAndSettle();
          expect(find.text('Por mi cuadra todavía no.'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'Gracias por avisar');
          await tester.pump();
          await tester.tap(find.byTooltip('Enviar'));
          await tester.pumpAndSettle();
          expect(find.text('Gracias por avisar'), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Gracias por avisar',
          );
          failSend = false;
          await tester.tap(find.byTooltip('Enviar'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            isEmpty,
          );
          await tester.pump(const Duration(seconds: 16));
          await tester.pumpAndSettle();
          expect(find.text('Por mi cuadra todavía no.'), findsOneWidget);
          expect(find.text('Gracias por avisar'), findsOneWidget);
          expect(writes, 2);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
