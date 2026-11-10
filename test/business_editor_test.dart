import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/business/business_editor.dart';
import 'package:harkai/features/business/business_point.dart';

void main() {
  testWidgets(
    'business flow validates, preserves details and requires location',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: BusinessEditor(
            point: const BusinessPoint({
              'id': '123456789012345678901234',
              'name': '',
              'description': '',
              'kind': 'restaurant',
              'latitude': -12.0,
              'longitude': -77.0,
              'payment_mode': 'one_time',
              'billing_status': 'active',
              'paid_at': '2026-11-01T00:00:00Z',
            }),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Completa este campo.'), findsWidgets);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Café del barrio',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Café y pan recién hecho',
      );
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Más detalles'), findsOneWidget);
      expect(find.text('Omitir este paso'), findsOneWidget);
      await tester.tap(find.text('Omitir este paso'));
      await tester.pumpAndSettle();
      expect(find.text('Dónde encontrarte'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Todo listo para enviar'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Más detalles'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Café del barrio'), findsOneWidget);
      expect(find.text('Café y pan recién hecho'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
