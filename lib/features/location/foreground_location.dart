import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

/// Observes location only while the application is visible. No background permission.
class ForegroundLocation with WidgetsBindingObserver {
  final Future<bool> Function(Position) onPosition;
  final bool Function(Object) onError;
  final bool track;
  StreamSubscription<Position>? updates;
  bool active = true, disposed = false;
  int generation = 0;
  ForegroundLocation({
    required this.onPosition,
    required this.onError,
    this.track = true,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> start({bool requestPermission = false}) async {
    final version = ++generation;
    await updates?.cancel();
    updates = null;
    try {
      final permission = await Geolocator.checkPermission();
      if (!requestPermission &&
          permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return false;
      }
      if (disposed || !active || version != generation) return false;
      final position = await currentLocation();
      if (disposed || !active || version != generation) return false;
      await onPosition(position);
      if (disposed || !active || version != generation) return false;
      if (!track) return true;
      updates =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 100,
            ),
          ).listen(
            (p) {
              if (!disposed && active && version == generation) onPosition(p);
            },
            onError: (Object error) {
              if (requestPermission) onError(error);
            },
          );
      return true;
    } catch (error) {
      if (!disposed && requestPermission) onError(error);
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active && track) {
      start();
    } else {
      generation++;
      updates?.cancel();
      updates = null;
    }
  }

  bool dispose() {
    disposed = true;
    active = false;
    generation++;
    updates?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    return true;
  }
}
