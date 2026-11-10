import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/core/app_controller.dart';
import 'package:harkai/core/app_scope.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/business/business_editor.dart';
import 'package:harkai/features/business/business_point.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'business details can be skipped, keyboard and gallery work: $brightness',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        var galleryRequests = 0;
        Map<String, dynamic>? payload;
        final app = AppController(
          ApiClient(
            transport: MockClient((request) async {
              expect(request.method, 'PUT');
              payload = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response('{"id":"business"}', 200);
            }),
          ),
        );
        await tester.pumpWidget(
          AppScope(
            controller: app,
            child: MaterialApp(
              theme: appTheme(brightness),
              home: BusinessEditor(
                photoPicker: (source) async {
                  expect(source, ImageSource.gallery);
                  galleryRequests++;
                  return null;
                },
                point: const BusinessPoint({
                  'id': 'business',
                  'name': 'Café del barrio',
                  'description': 'Café y pan recién hecho',
                  'kind': 'restaurant',
                  'latitude': -12.0,
                  'longitude': -77.0,
                  'website': 'https://example.test',
                  'address': 'Avenida Brasil 10',
                }),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Más detalles'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('business-name')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(find.text('Café del barrio'), findsOneWidget);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Añadir foto (opcional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Añadir foto (opcional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elegir de mi galería'));
        await tester.pumpAndSettle();
        expect(galleryRequests, 1);
        expect(payload, isNull);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Más detalles'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('business-website')),
          'invalid-draft',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Omitir este paso'));
        await tester.pumpAndSettle();
        expect(find.text('Dónde encontrarte'), findsOneWidget);
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(find.text('invalid-draft'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Usa una dirección https:// válida.'), findsOneWidget);
        await tester.tap(find.text('Omitir este paso'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();
        expect(payload?['website'], 'https://example.test');
        expect(payload?['address'], 'Avenida Brasil 10');
        expect(find.text('Ya recibimos tus cambios'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
