import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/shared/app_choice_field.dart';

void main() {
  testWidgets(
    'choice sheet prevents duplicate opens, handles keyboard and short screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String selected = 'a';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppChoiceField(
              label: 'Tipo',
              value: 'a',
              options: const {'a': 'Restaurante', 'b': 'Salud', 'c': 'Tienda'},
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AppChoiceField));
      await tester.tap(find.byType(AppChoiceField), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Tienda'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 'b');
      expect(find.text('Tienda'), findsNothing);
      await tester.tap(find.byType(AppChoiceField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Tienda'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
