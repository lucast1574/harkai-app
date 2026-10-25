import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:harkai/features/notifications/device_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Always, precise GPS and notifications are required; battery restriction stays advisory',
    () {
      const ready = DevicePermissions(
        notifications: true,
        gps: true,
        precise: true,
        background: true,
        batteryUnrestricted: false,
      );
      const foreground = DevicePermissions(
        notifications: true,
        gps: true,
        precise: true,
        background: false,
        batteryUnrestricted: true,
      );
      const approximate = DevicePermissions(
        notifications: true,
        gps: true,
        precise: false,
        background: true,
        batteryUnrestricted: true,
      );
      expect(ready.ready, true);
      expect(foreground.ready, false);
      expect(approximate.ready, false);
    },
  );
  test('Settings shortcuts request the intended Android destination', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DevicePermissions.channel, (
          MethodCall call,
        ) async {
          calls.add(call.method);
          return true;
        });
    await DevicePermissions.open('appSettings');
    await DevicePermissions.open('notificationSettings');
    expect(calls, ['appSettings', 'notificationSettings']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DevicePermissions.channel, null);
  });
}
