import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_scope.dart';
import '../location/location_service.dart';

/// One reminder per app visit, with automatic restoration after permission is granted.
class NotificationGate extends StatefulWidget {
  final Widget child;
  const NotificationGate({super.key, required this.child});
  @override
  State<NotificationGate> createState() => _NotificationGateState();
}

class _NotificationGateState extends State<NotificationGate>
    with WidgetsBindingObserver {
  bool checking = false, shown = false, dialogOpen = false;
  DateTime? backgroundAt;
  String? owner;
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
    final app = AppScope.of(context);
    if (owner != app.account?.id) {
      owner = app.account?.id;
      shown = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      backgroundAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (!dialogOpen && backgroundAt != null) {
        shown = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
    }
  }

  Future<void> check() async {
    if (!mounted || checking || dialogOpen) return;
    final app = AppScope.of(context);
    if (app.loading || app.capabilities['push_notifications'] != true) return;
    checking = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final location = await Geolocator.checkPermission();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final gps =
          location == LocationPermission.always ||
          location == LocationPermission.whileInUse;
      if (allowed && gps && await Geolocator.isLocationServiceEnabled()) {
        if (app.account != null &&
            (!app.notifications.enabled ||
                !app.notifications.tracking.running)) {
          final p = await currentLocation();
          if (mounted && app.account?.id == owner) {
            await app.notifications.activate(p.latitude, p.longitude);
          }
        }
        return;
      }
      if (shown || !mounted) return;
      shown = true;
      dialogOpen = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const _PermissionPrompt(),
      );
    } catch (_) {
      /* A network or plugin failure must not block the public map. */
    } finally {
      checking = false;
      dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PermissionPrompt extends StatefulWidget {
  const _PermissionPrompt();
  @override
  State<_PermissionPrompt> createState() => _PermissionPromptState();
}

class _PermissionPromptState extends State<_PermissionPrompt> {
  bool busy = false, settingsNeeded = false;
  String? error;
  Future<void> enable() async {
    if (settingsNeeded) {
      await Geolocator.openAppSettings();
      return;
    }
    setState(() => busy = true);
    try {
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        if (mounted) {
          setState(() {
            settingsNeeded = true;
            error =
                'Activa las notificaciones de Harkai en los ajustes del teléfono.';
          });
        }
        return;
      }
      final position = await currentLocation();
      if (!mounted) return;
      final app = AppScope.of(context);
      if (app.account != null) {
        await app.notifications.activate(position.latitude, position.longitude);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          settingsNeeded = true;
          error =
              'Revisa los permisos de ubicación y notificaciones de Harkai en tu teléfono.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      MediaQuery.paddingOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications_active_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Entérate antes de acercarte',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Activa los avisos de seguridad, eventos y negocios de tu zona. Harkai usa tu ubicación durante el recorrido, también con la pantalla bloqueada. Android muestra un aviso mientras este servicio está activo.',
        ),
        const SizedBox(height: 10),
        const Text(
          'Puedes cambiar los permisos desde los ajustes del teléfono.',
          style: TextStyle(fontSize: 12),
        ),
        if (error != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!)),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : enable,
            child: Text(
              busy
                  ? 'Activando…'
                  : settingsNeeded
                  ? 'Abrir ajustes'
                  : 'Activar avisos',
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
        ),
      ],
    ),
  );
}
