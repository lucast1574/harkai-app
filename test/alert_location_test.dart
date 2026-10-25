import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harkai/core/api_client.dart';
import 'package:harkai/features/notifications/alert_location.dart';

Position position(
  DateTime time, {
  double latitude = -12.04,
  double accuracy = 10,
}) => Position(
  latitude: latitude,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'walking sends authenticated coordinates, coalesces updates and stops with consent',
    () async {
      var now = DateTime.utc(2026, 10, 22);
      String? device = 'device';
      final stream = StreamController<Position>();
      final requests = <http.Request>[];
      final api = ApiClient(
        transport: MockClient((request) async {
          requests.add(request);
          return http.Response('{"id":"device"}', 200);
        }),
      );
      await api.save({'access_token': 'test', 'refresh_token': 'test'});
      final tracker = AlertLocation(
        api,
        () => device,
        checkPermission: () async => LocationPermission.whileInUse,
        watch: (_) => stream.stream,
        now: () => now,
      );
      await tracker.start();
      stream.add(position(now, accuracy: 500));
      await Future<void>.delayed(Duration.zero);
      expect(requests, isEmpty);
      stream.add(position(now));
      await Future<void>.delayed(Duration.zero);
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '/v1/me/devices/device/location');
      expect(requests.single.headers['Authorization'], 'Bearer test');
      expect(jsonDecode(requests.single.body)['latitude'], -12.04);
      expect(jsonDecode(requests.single.body)['accuracy'], 10);
      expect(
        DateTime.parse(
          jsonDecode(requests.single.body)['observed_at'] as String,
        ),
        now,
      );
      stream.add(position(now, latitude: -12.03));
      await Future<void>.delayed(Duration.zero);
      expect(await tracker.sync(), false);
      expect(requests.length, 1);
      now = now.add(const Duration(seconds: 31));
      expect(await tracker.sync(), true);
      expect(jsonDecode(requests.last.body)['latitude'], -12.03);
      device = null;
      await tracker.stop();
      expect(await tracker.sync(), false);
      expect(requests.length, 2);
      await stream.close();
    },
  );

  test(
    'stale, inaccurate, future and out of range positions never leave the device',
    () {
      final now = DateTime.utc(2026, 10, 22);
      expect(usableAlertPosition(position(now), now), true);
      expect(
        usableAlertPosition(
          position(now.subtract(const Duration(minutes: 3))),
          now,
        ),
        false,
      );
      expect(
        usableAlertPosition(position(now.add(const Duration(minutes: 1))), now),
        false,
      );
      expect(usableAlertPosition(position(now, latitude: 91), now), false);
      expect(
        usableAlertPosition(position(now, accuracy: double.nan), now),
        false,
      );
    },
  );
  test(
    'GPS stream interruption is visible and resumes with a fresh stream',
    () async {
      final first = StreamController<Position>(),
          second = StreamController<Position>();
      var subscriptions = 0;
      final api = ApiClient(
        transport: MockClient((_) async => http.Response('{}', 200)),
      );
      final tracker = AlertLocation(
        api,
        () => 'device',
        checkPermission: () async => LocationPermission.always,
        watch: (settings) {
          expect(settings.distanceFilter, 0);
          subscriptions++;
          return subscriptions == 1 ? first.stream : second.stream;
        },
      );
      await tracker.start();
      await first.close();
      expect(tracker.running, false);
      expect(tracker.error, isNotNull);
      tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(subscriptions, 2);
      expect(tracker.running, true);
      await tracker.stop();
      tracker.dispose();
      await second.close();
    },
  );
}
