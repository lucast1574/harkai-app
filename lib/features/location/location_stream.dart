import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/// One native GPS subscription. Background consent upgrades it even if the map
/// subscribed first; releasing that consent immediately downgrades the service.
class SharedLocationSource {
  final Stream<Position> Function(LocationSettings) nativeWatch;
  final _clients = <StreamController<Position>, LocationSettings>{};
  StreamSubscription<Position>? _native;
  Future<void> _pending = Future.value();
  String? _key;
  int _version = 0;
  SharedLocationSource({this.nativeWatch = nativePositions});
  Stream<Position> watch(LocationSettings settings) {
    late StreamController<Position> controller;
    controller = StreamController<Position>(
      onListen: () {
        _clients[controller] = settings;
        _schedule();
      },
      onCancel: () async {
        _clients.remove(controller);
        _schedule();
        await _pending;
      },
    );
    return controller.stream;
  }

  void _schedule() {
    _pending = _pending.then((_) => _configure()).catchError((Object error) {
      _key = null;
      for (final c in _clients.keys.toList()) {
        if (!c.isClosed) c.addError(error);
      }
    });
  }

  LocationSettings? _desired() {
    for (final s in _clients.values) {
      if (s is AndroidSettings && s.foregroundNotificationConfig != null) {
        return s;
      }
    }
    return _clients.values.firstOrNull;
  }

  Future<void> _configure() async {
    var desired = _desired();
    var key = desired == null ? null : jsonEncode(desired.toJson());
    if (desired != null && key == _key && _native != null) return;
    final version = ++_version;
    await _native?.cancel();
    _native = null;
    // Consent may have changed while native cancellation was in flight.
    desired = _desired();
    key = desired == null ? null : jsonEncode(desired.toJson());
    _key = key;
    if (desired == null) return;
    _native = nativeWatch(desired).listen(
      (p) {
        if (version != _version) return;
        for (final c in _clients.keys.toList()) {
          if (!c.isClosed) c.add(p);
        }
      },
      onError: (Object error) {
        if (version != _version) return;
        _key = null;
        for (final c in _clients.keys.toList()) {
          if (!c.isClosed) c.addError(error);
        }
      },
      onDone: () {
        if (version != _version) return;
        _key = null;
        for (final c in _clients.keys.toList()) {
          c.close();
        }
      },
    );
  }
}

Stream<Position> nativePositions(LocationSettings settings) =>
    Geolocator.getPositionStream(locationSettings: settings);
final sharedLocationSource = SharedLocationSource();
