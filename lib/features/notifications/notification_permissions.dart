import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_scope.dart';
import '../location/location_service.dart';
import 'device_permissions.dart';

class NotificationPermissions extends StatefulWidget {
  final bool sheet;
  const NotificationPermissions({super.key, this.sheet = false});
  @override
  State<NotificationPermissions> createState() =>
      _NotificationPermissionsState();
}

class _NotificationPermissionsState extends State<NotificationPermissions>
    with WidgetsBindingObserver {
  DevicePermissions? permissions;
  bool busy = false, initialized = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  Future<void> load() async {
    try {
      final status = await DevicePermissions.read();
      if (!mounted) return;
      setState(() {
        permissions = status;
        error = null;
      });
      final app = AppScope.of(context);
      if (status.ready && app.account != null) {
        if (!app.notifications.enabled) {
          final p = await currentLocation();
          await app.notifications.activate(p.latitude, p.longitude);
        } else {
          await app.notifications.tracking.start();
        }
        if (mounted && widget.sheet) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo comprobar la configuración. Vuelve a intentarlo.',
        );
      }
    }
  }

  Future<void> configure() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      var status = await DevicePermissions.read();
      if (!status.notifications) {
        await FirebaseMessaging.instance.requestPermission();
      }
      var location = await Geolocator.checkPermission();
      if (location == LocationPermission.denied) {
        location = await Geolocator.requestPermission();
      }
      status = await DevicePermissions.read();
      if (!status.gps) {
        await DevicePermissions.open('locationSettings');
      } else if (!status.precise || !status.background) {
        await DevicePermissions.open('appSettings');
      } else if (!status.notifications) {
        await DevicePermissions.open('notificationSettings');
      } else {
        await load();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Abre los ajustes del teléfono y revisa los permisos de Harkai.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget setting(
    IconData icon,
    String title,
    String description,
    bool enabled,
    String destination,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      icon,
      color: enabled
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      enabled ? 'Configurado' : description,
      style: const TextStyle(fontSize: 12),
    ),
    trailing: Icon(
      enabled
          ? Icons.check_circle_outline_rounded
          : Icons.chevron_right_rounded,
      size: 21,
    ),
    onTap: () async {
      try {
        await DevicePermissions.open(destination);
      } catch (_) {
        if (mounted) setState(() => error = 'No se pudo abrir Ajustes.');
      }
    },
  );
  @override
  Widget build(BuildContext context) {
    final p = permissions;
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        widget.sheet ? 0 : 16,
        24,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu zona, también en segundo plano',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Harkai usa tu ubicación precisa mientras te desplazas, incluso con la app minimizada o la pantalla bloqueada, para avisarte de riesgos, eventos y lugares cercanos. Android mostrará un aviso mientras se actualiza tu zona.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 10),
          const Text(
            'En Ajustes → Permisos → Ubicación, elige «Permitir siempre» y activa «Usar ubicación precisa».',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          AnimatedBuilder(
            animation: AppScope.of(context).notifications.tracking,
            builder: (context, _) {
              final app = AppScope.of(context);
              final tracking = app.notifications.tracking;
              final fresh =
                  tracking.lastSync != null &&
                  DateTime.now().difference(tracking.lastSync!) <
                      const Duration(minutes: 3);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  app.account == null
                      ? 'Inicia sesión para recibir avisos por proximidad.'
                      : tracking.error ??
                            (tracking.running && fresh
                                ? 'Tu ubicación se está actualizando para recibir avisos cercanos.'
                                : 'Esperando una ubicación precisa para actualizar tu zona.'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          if (p == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(),
            )
          else ...[
            setting(
              Icons.location_on_outlined,
              'Ubicación precisa',
              'Necesaria para avisarte al acercarte',
              p.precise,
              'appSettings',
            ),
            setting(
              Icons.route_outlined,
              'Ubicación todo el tiempo',
              'Elige «Permitir siempre» en Android',
              p.background,
              'appSettings',
            ),
            setting(
              Icons.notifications_active_outlined,
              'Notificaciones',
              'Permite los avisos de Harkai',
              p.notifications,
              'notificationSettings',
            ),
            if (!p.gps)
              setting(
                Icons.gps_off_rounded,
                'Ubicación del teléfono',
                'Activa el GPS',
                false,
                'locationSettings',
              ),
            if (!widget.sheet) ...[
              setting(
                Icons.photo_camera_outlined,
                'Cámara',
                'Se solicita al tomar la foto de un reporte',
                p.camera,
                'appSettings',
              ),
              setting(
                Icons.mic_none_rounded,
                'Micrófono',
                'Se solicita al describir un reporte con tu voz',
                p.microphone,
                'appSettings',
              ),
            ],
            setting(
              Icons.battery_saver_outlined,
              'Uso de batería en segundo plano',
              'Recomendado: permite Harkai sin restricciones',
              p.batteryUnrestricted,
              'batterySettings',
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : configure,
              child: Text(
                busy
                    ? 'Comprobando…'
                    : p?.ready == true
                    ? 'Comprobar seguimiento'
                    : 'Configurar permisos',
              ),
            ),
          ),
          if (widget.sheet)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ahora no'),
              ),
            ),
        ],
      ),
    );
    return widget.sheet
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('Permisos del teléfono')),
            body: content,
          );
  }
}
