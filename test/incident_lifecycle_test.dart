import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/core/models.dart';

void main() {
  Incident incident(int minutes, {bool confirmed = false}) =>
      Incident.fromJson({
        'id': 'example',
        'type': 'fire',
        'description': 'Reporte conservado',
        'status': 'active',
        'latitude': -12.0,
        'longitude': -77.0,
        'verified': true,
        'viewer_has_confirmed': confirmed,
        'created_at': DateTime.now()
            .subtract(Duration(minutes: minutes))
            .toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(hours: 3))
            .toIso8601String(),
      });
  test('Legacy expiry cannot keep a point active beyond 90 minutes', () {
    expect(incident(89).mapActive, isTrue);
    final archived = incident(91);
    expect(archived.mapActive, isFalse);
    expect(archived.canConfirm, isFalse);
    expect(archived.description, 'Reporte conservado');
  });
  test('A different neighbor can confirm; the same neighbor cannot repeat', () {
    expect(incident(5).confirmations, 1);
    expect(incident(5).canConfirm, isTrue);
    expect(incident(5, confirmed: true).canConfirm, isFalse);
  });
}
