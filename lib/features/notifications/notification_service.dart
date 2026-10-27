import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/api_client.dart';
import 'notification_display.dart';
import 'alert_location.dart';
import 'proximity_sound.dart';

class NotificationService {
  static const storageKey = 'harkai_push_subscription_v1';
  final ApiClient api;
  final String? Function() currentUser;
  final bool Function(String) onOpen;
  final display = NotificationDisplay();
  Map<String, dynamic>? subscription;
  StreamSubscription<String>? tokenChanges;
  StreamSubscription<RemoteMessage>? messages, opens;
  bool listening = false;
  int generation = 0;
  late final tracking = AlertLocation(
    api,
    () => enabled && subscription?['live_location'] == true
        ? (subscription?['device'] as String?)
        : null,
    onBusinessNotices: (notices) async {
      final owner = currentUser();
      final version = generation;
      for (final raw in notices) {
        if (owner != currentUser() || version != generation || !enabled) return;
        final n = raw as Map<String, dynamic>;
        final id = n["id"] as String?;
        final point = n["point_id"] as String?;
        if (id == null ||
            !RegExp(r"^[a-f0-9]{64}$").hasMatch(id) ||
            !validReportID(point)) {
          continue;
        }
        final saved = subscription!;
        final seen = Map<String, dynamic>.from(
          saved['notice_stages'] as Map? ?? {},
        );
        final key = '${n['kind']}:$point';
        final previous = seen[key] as Map?;
        final date = DateTime.tryParse(previous?['at'] as String? ?? '');
        final fresh =
            date != null &&
            DateTime.now().difference(date) < const Duration(hours: 24);
        final stage = (n['stage'] as num?)?.toInt() ?? 500;
        await display.showProximity(
          point!,
          n,
          alertAgain: proximityInterrupts(
            fresh ? (previous?['stage'] as num?)?.toInt() : null,
            stage,
            promoted: n['kind'] != 'incident',
          ),
        );
        if (owner != currentUser() || version != generation || !enabled) return;
        final previousStage = (previous?['stage'] as num?)?.toInt() ?? 500;
        seen[key] = {
          'stage': fresh && previousStage < stage ? previousStage : stage,
          'at': DateTime.now().toIso8601String(),
        };
        while (seen.length > 200) {
          seen.remove(seen.keys.first);
        }
        saved['notice_stages'] = seen;
        await api.storage.write(key: storageKey, value: jsonEncode(saved));
        if (owner != currentUser() || version != generation || !enabled) return;
        await api.request(
          "POST",
          "me/proximity-notices/$id/ack",
          body: {"stage": n["stage"] ?? 0},
        );
      }
    },
    onSynced: (position) async {
      final saved = subscription;
      if (saved == null || !enabled) return;
      saved['latitude'] = position.latitude;
      saved['longitude'] = position.longitude;
      await api.storage.write(key: storageKey, value: jsonEncode(saved));
    },
  );
  NotificationService(this.api, this.currentUser, this.onOpen);
  bool get ownsZone =>
      subscription != null &&
      currentUser() != null &&
      subscription?['user'] == currentUser();

  bool get enabled => ownsZone && subscription?['device'] is String;

  Future<bool> restore() async {
    final raw = await api.storage.read(key: storageKey);
    if (raw == null) return false;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      subscription = saved;
      if (saved['user'] != currentUser()) return stop();
      await setup();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return false;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await register(token);
      if (enabled && saved['live_location'] == true) await tracking.start();
      return enabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setup() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await display.initialize(open);
    if (listening) return true;
    listening = true;
    tokenChanges = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      try {
        if (enabled) await register(token);
      } catch (_) {
        /* Next activation retries. */
      }
    });
    messages = FirebaseMessaging.onMessage.listen((message) async {
      final id = message.data['report_id'];
      if (!enabled || !validReportID(id)) return;
      final owner = currentUser();
      try {
        final report = await api.request('GET', 'incidents/$id');
        final expiry = DateTime.tryParse(report['expires_at'] as String? ?? '');
        if (owner == currentUser() &&
            enabled &&
            report['status'] == 'active' &&
            (expiry == null || expiry.isAfter(DateTime.now()))) {
          await display.show(id as String);
        }
      } catch (_) {
        /* Hidden or unavailable reports do not generate foreground notices. */
      }
    });
    opens = FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => open(m.data['report_id']),
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) open(initial.data['report_id']);
    return true;
  }

  Future<bool> activate(double latitude, double longitude) async {
    final owner = currentUser();
    if (owner == null) return false;
    if (subscription != null && !enabled) await stop();
    subscription = {
      'user': owner,
      'latitude': latitude,
      'longitude': longitude,
      'live_location': true,
    };
    await setup();
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      subscription = null;
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      throw Exception(
        'Concede el permiso de notificaciones en el dispositivo.',
      );
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || owner != currentUser()) {
      throw Exception('No se pudo registrar el dispositivo.');
    }
    final registered = await register(token);
    if (registered) await tracking.start();
    return registered;
  }

  Future<bool> register(String token) async {
    final saved = subscription;
    final version = generation;
    if (saved == null || !ownsZone) return false;
    final result = await api.request(
      'PUT',
      'me/devices',
      body: {
        'token': token,
        'platform': 'android',
        'latitude': saved['latitude'],
        'longitude': saved['longitude'],
      },
    );
    if (version != generation || saved['user'] != currentUser()) return false;
    saved['device'] = result['id'];
    await api.storage.write(key: storageKey, value: jsonEncode(saved));
    return true;
  }

  Future<bool> stop({bool removeDevice = false}) async {
    await tracking.stop();
    final hadConsent = subscription != null;
    final id = subscription?['device'];
    if (removeDevice && id is String) {
      await api.request('DELETE', 'me/devices/$id');
    }
    generation++;
    subscription = null;
    await api.storage.delete(key: storageKey);
    if (listening) await display.cancel();
    if (hadConsent || Firebase.apps.isNotEmpty) {
      try {
        if (Firebase.apps.isEmpty) await Firebase.initializeApp();
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        /* Logout revokes Go session eligibility independently. */
      }
    }
    return true;
  }

  bool open(dynamic id) =>
      currentUser() != null &&
      id is String &&
      (validReportID(id) ||
          id.startsWith('support:') ||
          id.startsWith('business:') && validReportID(id.substring(9))) &&
      onOpen(id);
  bool validReportID(dynamic id) =>
      id is String && RegExp(r'^[a-f0-9]{24}$').hasMatch(id);
}
