import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/help/safety_report.dart';

void main() {
  testWidgets(
    'Missing mail app keeps contact visible and never claims delivery',
    (tester) async {
      Uri? composed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafetyReportButton(
              incidentId: 'report/with?characters',
              open: (uri) async {
                composed = uri;
                return false;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Denunciar contenido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguridad de menores'));
      await tester.pumpAndSettle();
      expect(composed!.scheme, 'mailto');
      expect(composed!.path, safetyEmail);
      expect(
        composed!.queryParameters['subject'],
        'Harkai · Seguridad de menores',
      );
      expect(
        composed!.queryParameters['body'],
        contains(
          'https://panel.harkai.lat/incidents/report%2Fwith%3Fcharacters',
        ),
      );
      expect(find.textContaining('Todavía no se ha enviado.'), findsOneWidget);
      expect(find.text(safetyEmail), findsOneWidget);
      expect(find.text('Copiar correo'), findsOneWidget);
    },
  );

  testWidgets('Concurrent taps open only one mail composer', (tester) async {
    final pending = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafetyReportButton(
            open: (_) {
              calls++;
              return pending.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Denunciar contenido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguridad de menores'));
    await tester.tap(find.text('Otro contenido indebido'));
    expect(calls, 1);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no se ha enviado.'), findsNothing);
  });
}
