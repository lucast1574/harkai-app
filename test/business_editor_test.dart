import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/business/business_editor.dart';

void main() {
  testWidgets(
    'business flow validates, preserves details and requires location',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: const BusinessEditor(),
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
      expect(find.text('Dónde encontrarte'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Elige la ubicación de tu negocio para continuar.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Café del barrio'), findsOneWidget);
      expect(find.text('Café y pan recién hecho'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
