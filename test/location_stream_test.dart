import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harkai/features/location/location_stream.dart';

void main() {
  test(
    'Apple background consent upgrades the map stream and revocation downgrades it',
    () async {
      final opened = <AppleSettings>[];
      final controllers = <StreamController<Position>>[];
      final source = SharedLocationSource(
        nativeWatch: (settings) {
          opened.add(settings as AppleSettings);
          final controller = StreamController<Position>();
          controllers.add(controller);
          return controller.stream;
        },
      );
      final map = source
          .watch(AppleSettings(allowBackgroundLocationUpdates: false))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(opened.single.allowBackgroundLocationUpdates, isFalse);
      final tracking = source
          .watch(AppleSettings(allowBackgroundLocationUpdates: true))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(opened.last.allowBackgroundLocationUpdates, isTrue);
      await tracking.cancel();
      expect(opened.last.allowBackgroundLocationUpdates, isFalse);
      await map.cancel();
      for (final controller in controllers) {
        await controller.close();
      }
    },
  );
  test(
    'Tracking upgrades an existing map stream and logout removes the foreground service',
    () async {
      final opened = <AndroidSettings>[];
      final controllers = <StreamController<Position>>[];
      var canceled = 0;
      final source = SharedLocationSource(
        nativeWatch: (settings) {
          opened.add(settings as AndroidSettings);
          final c = StreamController<Position>(onCancel: () => canceled++);
          controllers.add(c);
          return c.stream;
        },
      );
      final map = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      final tracking = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Harkai',
          notificationText: 'Ubicación activa',
        ),
      );
      final mapSubscription = source.watch(map).listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(opened.single.foregroundNotificationConfig, isNull);
      final trackingSubscription = source.watch(tracking).listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(opened.last.foregroundNotificationConfig, isNotNull);
      expect(opened.last.distanceFilter, 0);
      expect(canceled, 1);
      await trackingSubscription.cancel();
      expect(opened.last.foregroundNotificationConfig, isNull);
      expect(canceled, 2);
      await mapSubscription.cancel();
      expect(canceled, 3);
      for (final c in controllers) {
        await c.close();
      }
    },
  );
}
