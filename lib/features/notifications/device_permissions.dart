import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class DevicePermissions {
  static const channel = MethodChannel('harkai/device_permissions');
  final bool notifications,
      gps,
      precise,
      background,
      batteryUnrestricted,
      camera,
      microphone;
  const DevicePermissions({
    this.camera = false,
    this.microphone = false,
    required this.notifications,
    required this.gps,
    required this.precise,
    required this.background,
    required this.batteryUnrestricted,
  });
  bool get ready => notifications && gps && precise && background;
  static Future<DevicePermissions> read() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    final notification = await FirebaseMessaging.instance
        .getNotificationSettings();
    final native =
        await channel.invokeMapMethod<String, dynamic>('status') ?? {};
    return DevicePermissions(
      camera: native['camera'] == true,
      microphone: native['microphone'] == true,
      notifications:
          notification.authorizationStatus == AuthorizationStatus.authorized ||
          notification.authorizationStatus == AuthorizationStatus.provisional,
      gps: await Geolocator.isLocationServiceEnabled(),
      precise: native['precise'] == true,
      background: native['background'] == true,
      batteryUnrestricted: native['batteryUnrestricted'] == true,
    );
  }

  static Future<void> open(String destination) async {
    await channel.invokeMethod<bool>(destination);
  }
}
