import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/help/support_place.dart';
import 'package:harkai/features/map/map_target.dart';
import 'package:harkai/features/map/map_target_sheet.dart';

void main() {
  for (final entry in {
    'police': ('Comisaría', Icons.local_police_rounded),
    'fire_station': (
      'Estación de bomberos',
      Icons.local_fire_department_rounded,
    ),
  }.entries) {
    testWidgets('${entry.key} sheet identifies the emergency service', (
      tester,
    ) async {
      final place = SupportPlace.fromJson({
        'id': entry.key,
        'name': 'Sede de prueba',
        'kind': entry.key,
        'address': 'Dirección no publicada',
        'district': 'Lima',
        'source_url': '',
        'location_source_url': '',
        'reviewed_at': '2026-10-29',
        'latitude': -12,
        'longitude': -77,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SupportPlaceDetails(place: place)),
        ),
      );
      expect(find.text(entry.value.$1), findsOneWidget);
      expect(find.byIcon(entry.value.$2), findsOneWidget);
      expect(find.text('Centro de salud'), findsNothing);
      expect(find.text('Teléfono no disponible'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  }
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
