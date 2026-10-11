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

  Future<bool> cancel() async {
    await plugin.cancelAll();
    return true;
  }
}
