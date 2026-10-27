import 'package:flutter_test/flutter_test.dart';
import 'package:harkai/features/notifications/proximity_sound.dart';

void main() {
  test('Replays and moving away stay quiet; a closer risk can interrupt', () {
    expect(proximityInterrupts(250, 250, promoted: false), isFalse);
    expect(proximityInterrupts(50, 250, promoted: false), isFalse);
    expect(proximityInterrupts(500, 250, promoted: false), isTrue);
    expect(proximityInterrupts(250, 50, promoted: false), isTrue);
    expect(proximityInterrupts(null, 500, promoted: false), isFalse);
    expect(proximityInterrupts(null, 15, promoted: false), isTrue);
  });
  test('Promotions stay quiet at intermediate distance and never repeat', () {
    expect(proximityInterrupts(500, 250, promoted: true), isFalse);
    expect(proximityInterrupts(250, 50, promoted: true), isTrue);
    expect(proximityInterrupts(50, 50, promoted: true), isFalse);
  });
}
