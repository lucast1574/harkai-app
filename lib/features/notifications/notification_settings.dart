import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});
  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool busy = false;
  String? error;
  Future<bool> enablePush() async {
    setState(() {
      busy = true;
      error = null;
    });
    final app = AppScope.of(context);
    try {
      final position = await currentLocation();
      await app.notifications.activate(position.latitude, position.longitude);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> disablePush() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.of(context).notifications.stop(removeDevice: true);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ready = app.capabilities['push_notifications'] == true;
    final enabled = app.notifications.enabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notificaciones en este teléfono',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'También recibirás reportes no verificados. Se aplican tu radio y preferencias guardadas.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Al activar, Harkai actualizará tu ubicación mientras te mueves, también al minimizar la app o bloquear la pantalla, con un aviso permanente de Android. Puedes detenerlo aquí. Si fuerzas el cierre de la app o Android detiene el servicio, se reanudará al abrirla.',
            ),
            if (!ready)
              const MessageCard(
                'Las notificaciones están pendientes de configuración. Puedes consultar las alertas en el mapa.',
              ),
            if (enabled)
              const MessageCard('Dispositivo registrado para recibir alertas.'),
            if (enabled)
              AnimatedBuilder(
                animation: app.notifications.tracking,
                builder: (context, _) {
                  final tracking = app.notifications.tracking;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      tracking.error ??
                          (tracking.lastSync != null
                              ? 'Tu zona se está actualizando automáticamente.'
                              : tracking.running
                              ? 'Esperando una ubicación precisa para actualizar tu zona…'
                              : 'Activa el seguimiento para recibir alertas mientras te mueves.'),
                    ),
                  );
                },
              ),
            if (error != null) MessageCard(error!, error: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !ready || busy ? null : enablePush,
              child: Text(
                busy
                    ? 'Procesando…'
                    : enabled
                    ? 'Reactivar alertas durante mi recorrido'
                    : 'Activar alertas durante mi recorrido',
              ),
            ),
            if (enabled)
              TextButton(
                onPressed: busy ? null : disablePush,
                child: const Text('Desactivar este teléfono'),
              ),
          ],
        ),
      ),
    );
  }
}
