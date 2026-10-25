import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_scope.dart';
import '../location/location_service.dart';
import 'device_permissions.dart';
import 'notification_permissions.dart';

/// One reminder per app visit, with automatic restoration after permission is granted.
class NotificationGate extends StatefulWidget {
  final Widget child;
  const NotificationGate({super.key, required this.child});
  @override
  State<NotificationGate> createState() => _NotificationGateState();
}

class _NotificationGateState extends State<NotificationGate>
    with WidgetsBindingObserver {
  bool checking = false, shown = false, dialogOpen = false;
  DateTime? backgroundAt;
  String? owner;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (owner != app.account?.id) {
      owner = app.account?.id;
      shown = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      backgroundAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (!dialogOpen && backgroundAt != null) {
        shown = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
    }
  }

  Future<void> check() async {
    if (!mounted || checking || dialogOpen) return;
    final app = AppScope.of(context);
    if (app.loading || app.capabilities['push_notifications'] != true) return;
    checking = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final location = await Geolocator.checkPermission();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final gps =
          location == LocationPermission.always ||
          location == LocationPermission.whileInUse;
      final complete = await DevicePermissions.read();
      if (allowed && gps && await Geolocator.isLocationServiceEnabled()) {
        if (app.account != null &&
            (!app.notifications.enabled ||
                !app.notifications.tracking.running)) {
          if (app.notifications.enabled) {
            await app.notifications.tracking.start();
          } else {
            final p = await currentLocation();
            if (mounted && app.account?.id == owner) {
              await app.notifications.activate(p.latitude, p.longitude);
            }
          }
        }
        if (complete.ready) return;
      }
      if (shown || !mounted) return;
      shown = true;
      dialogOpen = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const NotificationPermissions(sheet: true),
      );
    } catch (_) {
      /* A network or plugin failure must not block the public map. */
    } finally {
      checking = false;
      dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
