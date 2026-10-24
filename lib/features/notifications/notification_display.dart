import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationDisplay {
  final plugin = FlutterLocalNotificationsPlugin();
  Future<bool> initialize(bool Function(dynamic) open) async {
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notifications'),
      ),
      onDidReceiveNotificationResponse: (response) => open(response.payload),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'harkai_reports',
            'Reportes de tu zona',
            description: 'Información comunitaria, también no verificada',
            importance: Importance.high,
          ),
        );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      open(launch?.notificationResponse?.payload);
    }
    return true;
  }

  Future<bool> show(String id) async {
    await plugin.show(
      int.parse(id.substring(0, 7), radix: 16),
      'Un reporte cerca de tu zona',
      'Información de la comunidad. Revisa su estado y recomendaciones.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'harkai_reports',
          'Reportes de tu zona',
          icon: 'ic_notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: id,
    );
    return true;
  }

  Future<bool> showSupport(String name, int meters, String payload) async {
    await plugin.show(
      2000000001,
      'Un lugar de salud cerca de ti',
      '$name · aprox. $meters m. Punto permanente de ayuda, no una alerta.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'harkai_support',
          'Lugares de salud cercanos',
          channelDescription:
              'Puntos permanentes de salud cerca de tu ubicación',
          icon: 'ic_notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: payload,
    );
    return true;
  }

  Future<bool> showBusiness(String id, String name) async {
    await plugin.show(
      1000000000 + int.parse(id.substring(0, 7), radix: 16),
      'Un negocio cerca de ti',
      '$name · Promocionado. Descúbrelo en Harkai.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'harkai_businesses',
          'Negocios cercanos',
          channelDescription: 'Avisos de puntos promocionados cercanos',
          icon: 'ic_notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: 'business:$id',
    );
    return true;
  }

  Future<bool> showProximity(String id, Map<String, dynamic> notice) async {
    final business = notice['kind'] != 'incident';
    final stage = (notice['stage'] as num?)?.toInt() ?? 500;
    await plugin.show(
      (business ? 1000000000 : 0) + int.parse(id.substring(0, 7), radix: 16),
      notice['title'] as String? ??
          (business ? 'Un negocio cerca de ti' : 'Un reporte cerca de ti'),
      notice['body'] as String? ??
          notice['name'] as String? ??
          'Revisa el punto en Harkai.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          business ? 'harkai_businesses' : 'harkai_reports',
          business ? 'Negocios cercanos' : 'Reportes de tu zona',
          icon: 'ic_notifications',
          importance: business ? Importance.defaultImportance : Importance.high,
          priority: business ? Priority.defaultPriority : Priority.high,
          onlyAlertOnce: false,
        ),
      ),
      payload: business ? 'business:$id' : id,
    );
    return stage > 0;
  }

  Future<bool> cancel() async {
    await plugin.cancelAll();
    return true;
  }
}
