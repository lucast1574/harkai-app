import 'dart:convert';
import '../../core/api_client.dart';
import '../notifications/notification_display.dart';
import 'support_proximity.dart';

class SupportProximityNotice {
  final ApiClient api;
  final NotificationDisplay display;
  final String? Function() currentUser;
  bool sending = false;
  SupportProximityNotice(this.api, this.display, this.currentUser);

  Future<bool> notify(
    List<NearbySupport> nearby, {
    required bool enabled,
  }) async {
    final owner = currentUser();
    if (!enabled || owner == null || nearby.isEmpty || sending) return false;
    sending = true;
    try {
      // One quiet reminder per device/account/day; browsing the map never triggers it.
      final key = 'harkai_support_notice_$owner';
      final now = DateTime.now().toUtc();
      final previous = DateTime.tryParse(
        await api.storage.read(key: key) ?? '',
      );
      if (previous != null &&
          now.difference(previous) < const Duration(hours: 24)) {
        return false;
      }
      if (owner != currentUser()) return false;
      final first = nearby.first;
      await display.showSupport(
        first.place.name,
        first.meters.round(),
        'support:${jsonEncode(first.place.toJson())}',
      );
      await api.storage.write(key: key, value: now.toIso8601String());
      return true;
    } catch (_) {
      return false; // The permanent map and proximity card stay available.
    } finally {
      sending = false;
    }
  }
}
