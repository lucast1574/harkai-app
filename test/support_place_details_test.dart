import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/help/support_place.dart';

const hospital = SupportPlace(
  id: 'hospital',
  name: 'Clínica San Felipe',
  kind: 'hospital',
  address: 'Dirección',
  district: 'Jesús María',
  source: 'https://www.gob.pe',
  locationSource: 'https://www.gob.pe',
  reviewed: '2026-10-23',
  latitude: -12.08,
  longitude: -77.05,
  phone: '+5112190000',
  phones: ['+5112190000', '+51999888777'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'compact hospital sheet opens each real contact in the device dialer',
    (tester) async {
      String? called;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          called = (call.arguments as Map)['url'] as String?;
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupportPlaceDetails(place: hospital)),
        ),
      );
      expect(find.text('Clínica San Felipe'), findsOneWidget);
      expect(find.text('Fuente institucional'), findsNothing);
      expect(find.textContaining('Fuentes consultadas'), findsNothing);
      expect(find.byType(FilledButton), findsNWidgets(2));
      await tester.tap(find.text('Llamar · +5112190000'));
      await tester.pump();
      expect(called, 'tel:+5112190000');
    },
  );
  test('notification roundtrip retains photos and multiple contacts', () {
    final data = hospital.toJson()
      ..['photo_urls'] = ['https://example.com/hospital.jpg'];
    final restored = SupportPlace.fromJson(data);
    expect(restored.photoUrls, ['https://example.com/hospital.jpg']);
    expect(restored.contactPhones, ['+5112190000', '+51999888777']);
  });
}
