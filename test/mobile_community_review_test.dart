import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/models.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/community/community_screen.dart';
import 'package:harkai/features/community/district_chat.dart';
import 'package:harkai/features/help/support_directory.dart';
import 'package:harkai/features/pets/pets_screen.dart';
import 'support_directory_test.dart' show DirectoryGps, place;

void main() {
  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets(
      'community threads, tabs and directories render without overflow in $brightness',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        final oldGps = GeolocatorPlatform.instance;
        GeolocatorPlatform.instance = DirectoryGps();
        addTearDown(() => GeolocatorPlatform.instance = oldGps);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = const bool.fromEnvironment('CAPTURE_MOBILE_REVIEW');
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
        final boundary = GlobalKey();
        final catalog = [
          {
            'id': '150113',
            'name': 'Jesús María',
            'province': 'Lima',
            'department': 'Lima',
          },
        ];
        final messages = [
          {
            'id': 'a'.padLeft(24, '0'),
            'body': '¿Ya volvió el agua por la avenida Brasil?',
            'district': 'Jesús María',
            'created_at': '2026-11-04T19:12:00Z',
          },
          {
            'id': 'b'.padLeft(24, '0'),
            'body': 'Mañana habrá una jornada de limpieza en el parque.',
            'district': 'Jesús María',
            'created_at': '2026-11-04T18:55:00Z',
          },
        ];
        final app =
            AppController(
                ApiClient(
                  transport: MockClient((r) async {
                    Object result = {'items': []};
                    if (r.url.path.endsWith('/catalog')) {
                      result = {'items': catalog};
                    }
                    if (r.url.path.endsWith('/geo/district')) {
                      result = {'district': catalog.first};
                    }
                    if (r.url.path.endsWith('/forum')) {
                      result = {'items': messages};
                    }
                    if (r.url.path.endsWith('/comments')) {
                      result = {
                        'items': [
                          {
                            'id': '1'.padLeft(24, '0'),
                            'body': 'Sí, por mi cuadra ya volvió.',
                            'author_name': 'Vecino anónimo',
                            'created_at': '2026-11-04T19:16:00Z',
                          },
                          {
                            'id': '2'.padLeft(24, '0'),
                            'body': 'Por la cuadra 8 todavía no tenemos agua.',
                            'author_name': 'Vecino anónimo',
                            'created_at': '2026-11-04T19:18:00Z',
                          },
                        ],
                      };
                    }
                    if (r.url.path.contains('/incidents')) {
                      result = {
                        'items': [
                          {
                            'id': 'c'.padLeft(24, '0'),
                            'type': 'pet',
                            'description':
                                'Perrita encontrada con collar azul cerca del parque.',
                            'status': 'active',
                            'latitude': -12.073,
                            'longitude': -77.06,
                            'verified': false,
                            'district': 'Jesús María',
                            'created_at': DateTime.now()
                                .toUtc()
                                .toIso8601String(),
                          },
                        ],
                      };
                    }
                    if (r.url.path.endsWith('/support/places')) {
                      result = {
                        'items': [
                          place('Centro de salud', -12.073).toJson(),
                          place('Comisaría', -12.074, kind: 'police').toJson(),
                        ],
                      };
                    }
                    return http.Response(
                      jsonEncode(result),
                      200,
                      headers: {
                        'content-type': 'application/json; charset=utf-8',
                      },
                    );
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
        Widget wrap(Widget body, String title) => AppScope(
          controller: app,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('es')],
            theme: appTheme(brightness),
            builder: (context, child) =>
                RepaintBoundary(key: boundary, child: child!),
            home: Scaffold(
              appBar: AppBar(title: Text(title)),
              body: body,
            ),
          ),
        );
        Future<void> screenshot(String name) async {
          if (!capture) return;
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '.release-work/mobile-review/$name-${brightness.name}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await tester.pumpWidget(
          wrap(CommunityScreen(onMap: (_) {}), 'Comunidad'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DistrictChat), findsOneWidget);
        expect(find.text(messages.first['body']!), findsOneWidget);
        await screenshot('community');
        await tester.enterText(
          find.byType(TextField),
          'Borrador que se conserva',
        );
        await tester.tap(find.text('Alertas cercanas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chat del distrito'));
        await tester.pumpAndSettle();
        expect(find.text('Borrador que se conserva'), findsOneWidget);
        await tester.tap(find.text('Ver hilo').first);
        await tester.pumpAndSettle();
        await screenshot('thread');
        expect(find.text('Responder en este hilo'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Small display with larger text must retain the composer and navigation.
        tester.view.physicalSize = const Size(320, 640);
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.physicalSize = const Size(390, 844);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          wrap(SupportDirectory(onMap: (_) {}), 'Centros de ayuda'),
        );
        await tester.pumpAndSettle();
        await screenshot('support');
        expect(find.text('Centro de salud'), findsOneWidget);
        await tester.pumpWidget(
          wrap(PetsScreen(onMap: (_) {}, onCreate: () async {}), 'Mascotas'),
        );
        await tester.pumpAndSettle();
        await screenshot('pets');
        expect(find.textContaining('Perrita encontrada'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
