import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'package:harkai/features/community/district_chat.dart';
import 'package:harkai/features/community/comment_repository.dart';

class ChatGps extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final authenticated in [false, true]) {
    testWidgets('district selection and chat, authenticated=$authenticated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gps = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = ChatGps();
      addTearDown(() => GeolocatorPlatform.instance = gps);
      int writes = 0, replyWrites = 0;
      final replies = <Map<String, dynamic>>[];
      final catalog = [
        {
          'id': '130101',
          'name': 'Trujillo',
          'province': 'Trujillo',
          'department': 'La Libertad',
        },
      ];
      final messages = [
        {
          'id': 'aaaaaaaaaaaaaaaaaaaaaaaa',
          'body': '¿Cómo está el parque hoy?',
          'created_at': '2026-11-03T15:00:00Z',
          'district': 'Trujillo',
          'province': 'Trujillo',
          'can_delete': false,
        },
      ];
      final app = AppController(
        ApiClient(
          transport: MockClient((r) async {
            if (r.url.path.endsWith('/comments')) {
              if (r.method == 'POST') {
                replyWrites++;
                expect(jsonDecode(r.body).containsKey('district_id'), false);
                expect(
                  r.url.path,
                  '/v1/forum/bbbbbbbbbbbbbbbbbbbbbbbb/comments',
                );
                final reply = {
                  'id': 'cccccccccccccccccccccccc',
                  'body': jsonDecode(r.body)['body'],
                  'created_at': '2026-11-03T16:00:00Z',
                };
                replies.add(reply);
                return http.Response(jsonEncode(reply), 201);
              }
              return http.Response(jsonEncode({'items': replies}), 200);
            }
            if (r.method == 'POST') {
              writes++;
              expect(jsonDecode(r.body)['district_id'], '130101');
              return http.Response(
                jsonEncode({
                  ...messages[0],
                  'id': 'bbbbbbbbbbbbbbbbbbbbbbbb',
                  'body': jsonDecode(r.body)['body'],
                }),
                201,
                headers: {"content-type": "application/json; charset=utf-8"},
              );
            }
            return http.Response(
              jsonEncode({
                'items': r.url.path.endsWith('/catalog') ? catalog : messages,
              }),
              200,
              headers: {"content-type": "application/json; charset=utf-8"},
            );
          }),
        ),
      );
      if (authenticated) {
        app.account = const Account(
          'test',
          'Real name',
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
            home: const Scaffold(body: DistrictChat()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Elige un distrito para abrir su chat'),
        findsOneWidget,
      );
      await tester.tap(find.text('Elegir distrito'));
      await tester.pumpAndSettle();
      for (final label in [
        'Elige un departamento',
        'Elige una provincia',
        'Elige un distrito',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text(
                label == 'Elige un departamento' ? 'La Libertad' : 'Trujillo',
              )
              .last,
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('¿Cómo está el parque hoy?'), findsOneWidget);
      expect(find.text('Real name'), findsNothing);
      expect(find.text('private@example.test'), findsNothing);
      if (authenticated) {
        await tester.enterText(
          find.byType(TextField),
          'Nos vemos en el parque',
        );
        await tester.pump();
        await tester.tap(find.byTooltip('Enviar'));
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(find.text('Nos vemos en el parque'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Borrador del distrito');
        await tester.tap(find.text('Ver hilo').first);
        await tester.pumpAndSettle();
        expect(find.text('Conversación'), findsOneWidget);
        expect(find.text('Mensaje original'), findsOneWidget);
        expect(find.text('Responder en este hilo'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Llevo una pelota');
        await tester.pump();
        await tester.tap(find.byTooltip('Enviar'));
        await tester.pumpAndSettle();
        expect(replyWrites, 1);
        expect(writes, 1);
        expect(find.text('Llevo una pelota'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Llevo una pelota'), findsNothing);
        expect(find.text('Borrador del distrito'), findsOneWidget);
        expect(find.text('Nuevo mensaje al distrito'), findsOneWidget);
      } else {
        expect(find.text('Ingresar para conversar'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(writes, 0);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  test('forum replies use the forum endpoint', () async {
    final api = ApiClient(
      transport: MockClient((r) async {
        expect(r.url.path, '/v1/forum/aaaaaaaaaaaaaaaaaaaaaaaa/comments');
        return http.Response('{"items":[]}', 200);
      }),
    );
    expect(
      (await CommentRepository(
        api,
        'aaaaaaaaaaaaaaaaaaaaaaaa',
        namespace: 'forum',
      ).list()).items,
      isEmpty,
    );
  });
}
