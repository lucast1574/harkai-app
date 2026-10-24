import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api_client.dart';

/// Owned by the notification subscription, independent of map navigation.
class AlertLocation extends ChangeNotifier with WidgetsBindingObserver {
  final ApiClient api;
  final String? Function() device;
  final Future<LocationPermission> Function() checkPermission;
  final Stream<Position> Function(LocationSettings) watch;
  final DateTime Function() now;
  final Future<void> Function(Position)? onSynced;
  final Future<void> Function(List<dynamic>)? onBusinessNotices;
  StreamSubscription<Position>? _positions;
  Timer? _timer;
  Position? _latest, _sent;
  DateTime? lastSync;
  DateTime? _lastAttempt;
  String? error;
  bool running = false, _sending = false;
  int _generation = 0;
  AlertLocation(
    this.api,
    this.device, {
    this.checkPermission = Geolocator.checkPermission,
    this.watch = watchAlertPositions,
    this.now = DateTime.now,
    this.onSynced,
    this.onBusinessNotices,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> start() async {
    if (running || device() == null) return running;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    final version = ++_generation;
    final permission = await checkPermission();
    if (version != _generation || device() == null) return false;
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      error =
          'Activa el permiso de ubicación para recibir alertas en tu recorrido.';
      notifyListeners();
      return false;
    }
    if (device() == null) return false;
    running = true;
    error = null;
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 25,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Alertas durante tu recorrido',
              notificationText:
                  'Harkai actualiza tu zona mientras te mueves. Gestiona las alertas en Mi cuenta.',
              notificationChannelName: 'Ubicación para alertas',
              notificationIcon: AndroidResource(name: 'ic_notifications'),
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 25,
          );
    _positions = watch(settings).listen(
      (position) {
        if (version != _generation) return;
        _latest = position;
        if (lastSync == null) unawaited(sync());
      },
      onError: (Object failure) {
        if (version != _generation) return;
        error =
            'No se está recibiendo ubicación. Revisa el GPS y sus permisos.';
        notifyListeners();
      },
    );
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(sync()),
    );
    notifyListeners();
    return true;
  }

  Future<bool> sync() async {
    final position = _latest;
    final id = device();
    if (!running ||
        _sending ||
        id == null ||
        position == null ||
        !usableAlertPosition(position, now())) {
      return false;
    }
    if (_lastAttempt != null &&
        now().difference(_lastAttempt!) < const Duration(seconds: 30)) {
      return false;
    }
    if (_sent != null &&
        lastSync != null &&
        error == null &&
        now().difference(lastSync!) < const Duration(minutes: 2) &&
        Geolocator.distanceBetween(
              _sent!.latitude,
              _sent!.longitude,
              position.latitude,
              position.longitude,
            ) <
            25) {
      return false;
    }
    _sending = true;
    _lastAttempt = now();
    final version = _generation;
    try {
      final response = await api.request(
        'PATCH',
        'me/devices/$id/location',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'observed_at': position.timestamp.toUtc().toIso8601String(),
        },
      );
      if (version != _generation || id != device()) return false;
      lastSync = now();
      _sent = position;
      error = null;
      await onSynced?.call(position);
      if (version == _generation && id == device()) {
        try {
          await onBusinessNotices?.call(
            response["business_notices"] as List? ?? [],
          );
        } catch (_) {
          /* Pending notices are retried on the next location update. */
        }
      }
      notifyListeners();
      return true;
    } catch (_) {
      if (version == _generation) {
        error =
            'No se pudo actualizar tu zona de alertas. Se reintentará automáticamente.';
        notifyListeners();
      }
      return false;
    } finally {
      _sending = false;
    }
  }

  Future<bool> stop() async {
    _generation++;
    running = false;
    _timer?.cancel();
    _timer = null;
    await _positions?.cancel();
    _positions = null;
    _latest = _sent = null;
    lastSync = null;
    _lastAttempt = null;
    error = null;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _generation++;
    running = false;
    _timer?.cancel();
    unawaited(_positions?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && device() != null) {
      if (running) {
        unawaited(sync());
      } else {
        unawaited(start());
      }
    }
  }
}

Stream<Position> watchAlertPositions(LocationSettings settings) =>
    Geolocator.getPositionStream(locationSettings: settings);

bool usableAlertPosition(Position position, DateTime now) =>
    position.latitude.isFinite &&
    position.longitude.isFinite &&
    position.latitude.abs() <= 90 &&
    position.longitude.abs() <= 180 &&
    position.accuracy.isFinite &&
    position.accuracy >= 0 &&
    position.accuracy <= 100 &&
    now.difference(position.timestamp) <= const Duration(minutes: 2) &&
    position.timestamp.difference(now) <= const Duration(seconds: 30);
