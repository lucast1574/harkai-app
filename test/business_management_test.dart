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
import 'package:harkai/features/business/business_directory.dart';

void main() {
  testWidgets(
    'mobile manages existing access without registration or payment links',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests = <String>[];
      Map<String, dynamic> business(
        String id,
        String status, {
        String mode = 'one_time',
      }) => {
        'id': id,
        'name': id,
        'kind': 'restaurant',
        'description': 'Comida del barrio',
        'latitude': -12.0,
        'longitude': -77.0,
        'enabled': true,
        'moderation': 'approved',
        'payment_mode': mode,
        'billing_status': status,
        if (status == 'active' && mode == 'one_time')
          'paid_at': '2026-11-01T00:00:00Z',
      };
      final controller =
          AppController(
              ApiClient(
                transport: MockClient((r) async {
                  requests.add('${r.method} ${r.url.path}');
                  if (r.method == 'PATCH') {
                    return http.Response(
                      jsonEncode(
                        business('pagado', 'active')..['enabled'] = false,
                      ),
                      200,
                    );
                  }
                  return http.Response(
                    jsonEncode({
                      'items': [
                        business('pagado', 'active'),
                        business('sin pagar', 'pending'),
                        business('reembolsado', 'refunded'),
                        business('anterior', 'active', mode: 'free'),
                      ],
                    }),
                    200,
                  );
                }),
              ),
            )
            ..account = const Account(
              'owner',
              'Vecino',
              'owner@example.test',
              'user',
              Preferences(),
            );
      await controller.api.save({
        'access_token': 'test',
        'refresh_token': 'test',
      });
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            theme: appTheme(Brightness.light),
            home: const Scaffold(body: BusinessDirectory(own: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('pagado'), findsOneWidget);
      expect(find.text('anterior'), findsOneWidget);
      final subtitleBottom = tester
          .getRect(
            find.text(
              'Administra tus negocios con acceso vigente: actualiza sus datos, ofertas y disponibilidad.',
            ),
          )
          .bottom;
      final firstCardTop = tester.getRect(find.byType(Card).first).top;
      expect(firstCardTop - subtitleBottom, greaterThanOrEqualTo(16));
      expect(find.text('sin pagar'), findsNothing);
      expect(find.text('reembolsado'), findsNothing);
      expect(find.text('Registrar negocio'), findsNothing);
      expect(find.textContaining('Pagar'), findsNothing);
      expect(find.textContaining('Stripe'), findsNothing);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(requests, contains('PATCH /v1/me/businesses/pagado/enabled'));
      expect(requests.where((r) => r.startsWith('POST')), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
