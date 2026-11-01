import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permission = await Geolocator.checkPermission();
      return DevicePermissions(
        notifications:
            notification.authorizationStatus ==
                AuthorizationStatus.authorized ||
            notification.authorizationStatus == AuthorizationStatus.provisional,
        gps: await Geolocator.isLocationServiceEnabled(),
        precise:
            await Geolocator.getLocationAccuracy() ==
            LocationAccuracyStatus.precise,
        background: permission == LocationPermission.always,
        batteryUnrestricted: true,
      );
    }
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (destination == 'location') {
        await Geolocator.requestPermission();
      } else {
        await Geolocator.openAppSettings();
      }
      return;
    }
    await channel.invokeMethod<bool>(destination);
  }
}
