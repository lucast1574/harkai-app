import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harkai/features/location/foreground_location.dart';

Position point(DateTime time, {double accuracy = 10}) => Position(
  latitude: -12.04,
  longitude: -77.04,
  timestamp: time,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class SlowGps extends GeolocatorPlatform {
  final Position cached;
  final current = Completer<Position>();
  final ready = Completer<void>();
  final updates = StreamController<Position>();
  SlowGps(this.cached);
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => cached;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      current.future;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    ready.complete();
    return updates.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'cached camera and live updates do not wait for a slow GPS request',
    () async {
      final original = GeolocatorPlatform.instance;
      final provider = SlowGps(
        point(DateTime.now().subtract(const Duration(minutes: 1))),
      );
      GeolocatorPlatform.instance = provider;
      final cached = <Position>[], fresh = <Position>[], errors = <Object>[];
      final location = ForegroundLocation(
        onCachedPosition: (p) async {
          cached.add(p);
          return true;
        },
        onPosition: (p) async {
          fresh.add(p);
          return true;
        },
        onError: (e) {
          errors.add(e);
          return true;
        },
      );
      try {
        final starting = location.start(requestPermission: true);
        await provider.ready.future;
        expect(cached, hasLength(1));
        expect(fresh, isEmpty);
        provider.updates.add(point(DateTime.now()));
        await Future<void>.delayed(Duration.zero);
        expect(fresh, hasLength(1));
        provider.current.completeError(TimeoutException('slow GPS'));
        await starting;
        expect(errors, isEmpty);
        provider.updates.add(point(DateTime.now()));
        await Future<void>.delayed(Duration.zero);
        expect(fresh, hasLength(2));
      } finally {
        location.dispose();
        GeolocatorPlatform.instance = original;
        await provider.updates.close();
      }
    },
  );
  test('stale and imprecise cached locations cannot seed the camera', () {
    final now = DateTime.now();
    expect(
      usableCachedPosition(
        point(now.subtract(const Duration(minutes: 1))),
        now,
      ),
      true,
    );
    expect(
      usableCachedPosition(point(now.subtract(const Duration(hours: 1))), now),
      false,
    );
    expect(usableCachedPosition(point(now, accuracy: 1000), now), false);
    expect(
      usableCachedPosition(point(now.add(const Duration(minutes: 1))), now),
      false,
    );
  });
}
