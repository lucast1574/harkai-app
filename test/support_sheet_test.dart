import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/help/support_place.dart';
import 'package:harkai/features/map/map_target.dart';
import 'package:harkai/features/map/map_target_sheet.dart';

void main() {
  testWidgets(
    'Health sheet has one identity, address, call action and close control',
    (tester) async {
      const place = SupportPlace(
        id: 'health-test',
        name: 'Centro de salud',
        kind: 'health_center',
        address: 'Avenida Perú 120',
        district: 'Jesús María',
        source: '',
        locationSource: '',
        reviewed: '2026-10-24',
        latitude: -12,
        longitude: -77,
        phone: '+51999999999',
      );
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTargetSheet(
              target: MapTarget.place(place),
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lugar de ayuda'), findsNothing);
      expect(
        find.text('Desliza hacia arriba para ver los detalles'),
        findsNothing,
      );
      expect(find.byType(SupportPlaceDetails), findsOneWidget);
      expect(find.text('Avenida Perú 120 · Jesús María'), findsOneWidget);
      expect(find.text('Llamar · +51999999999'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar ficha'));
      expect(closed, isTrue);
    },
  );
}
