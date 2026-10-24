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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alertas en este teléfono',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !ready
                            ? 'No disponibles por ahora'
                            : enabled
                            ? 'Activadas'
                            : 'Desactivadas',
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: enabled,
                    onChanged: !ready
                        ? null
                        : (value) => value ? enablePush() : disablePush(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Usa tu ubicación en segundo plano para avisarte de reportes cercanos.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            if (enabled)
              AnimatedBuilder(
                animation: app.notifications.tracking,
                builder: (context, _) {
                  final tracking = app.notifications.tracking;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tracking.error != null)
                        MessageCard(tracking.error!, error: true),
                      if (!tracking.running)
                        TextButton(
                          onPressed: busy ? null : enablePush,
                          child: const Text('Reanudar seguimiento'),
                        ),
                    ],
                  );
                },
              ),
            if (error != null) MessageCard(error!, error: true),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: Border(),
              collapsedShape: Border(),
              title: Text('Cómo funcionan', style: TextStyle(fontSize: 13)),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Se aplican tu radio y preferencias. Las alertas pueden incluir reportes no verificados. Android muestra un aviso mientras se actualiza tu zona, incluso con la pantalla bloqueada. Si el sistema detiene el servicio, se reanuda al abrir Harkai. Puedes desactivarlo aquí.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
