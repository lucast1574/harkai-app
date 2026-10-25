import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'location_stream.dart';

/// The map listens while visible; consented notifications own the shared background service.
class ForegroundLocation with WidgetsBindingObserver {
  final Future<bool> Function(Position) onPosition;
  final bool Function(Object) onError;
  final bool track;
  final Future<bool> Function(Position)? onCachedPosition;
  StreamSubscription<Position>? updates;
  bool active = true, disposed = false;
  int generation = 0;
  ForegroundLocation({
    required this.onPosition,
    required this.onError,
    this.track = true,
    this.onCachedPosition,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> start({bool requestPermission = false}) async {
    final version = ++generation;
    await updates?.cancel();
    updates = null;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (requestPermission) {
          onError(
            Exception('Activa el permiso de ubicación para centrar el mapa.'),
          );
        }
        return false;
      }
      if (disposed || !active || version != generation) return false;
      // Show a recent device fix immediately without waiting for fresh GPS.
      try {
        final cached = await Geolocator.getLastKnownPosition().timeout(
          const Duration(milliseconds: 750),
        );
        if (!disposed &&
            active &&
            version == generation &&
            cached != null &&
            usableCachedPosition(cached, DateTime.now())) {
          await onCachedPosition?.call(cached);
        }
      } catch (_) {
        // A missing cache must never prevent starting the GPS stream.
      }
      if (disposed || !active || version != generation) return false;
      var receivedPosition = false;
      if (track) {
        updates = sharedLocationSource
            .watch(
              AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
                intervalDuration: const Duration(seconds: 5),
              ),
            )
            .listen(
              (p) {
                if (!disposed && active && version == generation) {
                  receivedPosition = true;
                  onPosition(p);
                }
              },
              onError: (Object error) {
                if (!disposed &&
                    active &&
                    version == generation &&
                    requestPermission) {
                  onError(error);
                }
              },
            );
      }
      // Subscribe first so a slow or timed-out one-shot fix cannot block updates.
      try {
        final position = await currentLocation();
        if (disposed || !active || version != generation) return false;
        if (!receivedPosition) await onPosition(position);
      } catch (error) {
        if (!receivedPosition &&
            !disposed &&
            active &&
            version == generation &&
            requestPermission) {
          onError(error);
        }
      }
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

/// Cached fixes are for the initial camera only, never proximity or reporting.
bool usableCachedPosition(Position position, DateTime now) {
  final age = now.difference(position.timestamp);
  return age >= Duration.zero &&
      age <= const Duration(minutes: 10) &&
      position.accuracy.isFinite &&
      position.accuracy >= 0 &&
      position.accuracy <= 250 &&
      position.latitude.isFinite &&
      position.latitude.abs() <= 90 &&
      position.longitude.isFinite &&
      position.longitude.abs() <= 180;
}
