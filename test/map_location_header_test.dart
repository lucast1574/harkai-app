import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/core/theme.dart';
import 'package:harkai/features/map/map_location_header.dart';

void main() {
  testWidgets(
    'header shows resolved locality and graphic flag without a zone selector',
    (tester) async {
      var profileOpens = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.dark),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MapLocationHeader(
                district: 'San Borja',
                province: 'Lima',
                hasPosition: true,
                onProfile: () => profileOpens++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('San Borja, Lima'), findsOneWidget);
      expect(find.text('Perú'), findsOneWidget);
      expect(find.text('harkai'), findsNothing);
      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
      expect(find.byTooltip('Mi cuenta'), findsOneWidget);
      await tester.tap(find.byTooltip('Mi cuenta'));
      expect(profileOpens, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unresolved GPS never invents a district or country', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MapLocationHeader(hasPosition: false)),
      ),
    );
    expect(find.text('Buscando ubicación'), findsOneWidget);
    expect(find.text('Perú'), findsNothing);
  });
}
