import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  testWidgets('offer and details save together, errors preserve the draft', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (Platform.environment['BUSINESS_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        for (final family in [
          'Roboto',
          'Ahem',
          'MaterialIcons',
          'Segoe UI',
          '.SF UI Text',
          '.SF UI Display',
          '.SF Pro Text',
          '.SF Pro Display',
        ]) {
          final file = family == 'MaterialIcons'
              ? 'MaterialIcons-Regular.otf'
              : 'roboto-regular.ttf';
          final loader = FontLoader(family)
            ..addFont(
              File(
                'C:/flutter/flutter/bin/cache/artifacts/material_fonts/$file',
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await loader.load();
        }
      });
    }
    final payloads = <Map<String, dynamic>>[];
    final api = ApiClient(
      transport: MockClient((request) async {
        payloads.add(jsonDecode(request.body) as Map<String, dynamic>);
        return payloads.length == 1
            ? http.Response('{"error":{"code":"unavailable"}}', 503)
            : http.Response('{"id":"123456789012345678901234"}', 200);
      }),
    );
    await api.save({'access_token': 'test', 'refresh_token': 'test'});
    final key = GlobalKey();
    await tester.pumpWidget(
      AppScope(
        controller: AppController(api),
        child: MaterialApp(
          theme: appTheme(Brightness.light),
          home: RepaintBoundary(
            key: key,
            child: const BusinessEditor(
              point: BusinessPoint({
                'id': '123456789012345678901234',
                'name': 'Café del barrio',
                'kind': 'restaurant',
                'description': 'Café y pan recién hecho',
                'latitude': -12.0464,
                'longitude': -77.0428,
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (Platform.environment['BUSINESS_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../.qa/mobile-business-details.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      '15 % en tu primera visita',
    );
    await tester.enterText(find.byType(TextFormField).last, 'vecinos15');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar a revisión gratis'));
    await tester.pumpAndSettle();
    expect(find.text('15 % en tu primera visita'), findsOneWidget);
    expect(find.text('Enviar a revisión gratis'), findsOneWidget);
    await tester.tap(find.text('Enviar a revisión gratis'));
    await tester.pumpAndSettle();
    expect(payloads, hasLength(2));
    expect(payloads.last['name'], 'Café del barrio');
    expect(payloads.last['offer'], '15 % en tu primera visita');
    expect(payloads.last['discount_code'], 'VECINOS15');
    expect(find.text('Ya recibimos tu negocio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
