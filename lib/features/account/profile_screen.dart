import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), radius = TextEditingController();
  String notifications = 'all', language = 'es', theme = 'system';
  bool initialized = false, busy = false;
  String? error, message;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      final user = AppScope.of(context).account;
      if (user != null) {
        name.text = user.name;
        radius.text = '${user.preferences.radius}';
        notifications = user.preferences.notifications;
        language = user.preferences.language;
        theme = user.preferences.theme;
        initialized = true;
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    radius.dispose();
    super.dispose();
  }

  Future<bool> save() async {
    if (!form.currentState!.validate()) return false;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    final app = AppScope.of(context);
    try {
      await app.api.request('PATCH', 'me', body: {'name': name.text.trim()});
      await app.api.request(
        'PUT',
        'me/preferences',
        body: Preferences(
          notifications: notifications,
          radius: int.parse(radius.text),
          language: language,
          theme: theme,
        ).toJson(),
      );
      await app.reloadAccount();
      if (mounted) {
        setState(
          () => message = 'Tu perfil y preferencias quedaron guardados.',
        );
      }
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
    final user = AppScope.of(context).account;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
      children: [
        const PageHeading(
          'Tu cuenta, a tu manera',
          'Preferencias compartidas entre la web y la app.',
        ),
        if (user != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppField(
                      label: 'Nombre',
                      controller: name,
                      maxLength: 80,
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Escribe al menos dos caracteres.'
                          : null,
                    ),
                    Text(user.email),
                    const SizedBox(height: 10),
                    Text('Rol: ${user.role}'),
                    const SizedBox(height: 22),
                    DropdownButtonFormField<String>(
                      initialValue: notifications,
                      decoration: const InputDecoration(
                        labelText: 'Qué alertas consultar',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Todas, incluidas las no verificadas'),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Emergencias y seguridad'),
                        ),
                        DropdownMenuItem(
                          value: 'none',
                          child: Text('Desactivadas'),
                        ),
                      ],
                      onChanged: (v) => setState(() => notifications = v!),
                    ),
                    const SizedBox(height: 16),
                    AppField(
                      label: 'Radio de alertas (metros)',
                      controller: radius,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final r = int.tryParse(v ?? '');
                        return r == null || r < 100 || r > 10000
                            ? 'Elige de 100 a 10000 metros.'
                            : null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: theme,
                      decoration: const InputDecoration(labelText: 'Tema'),
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('Usar el sistema'),
                        ),
                        DropdownMenuItem(value: 'light', child: Text('Claro')),
                        DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
                      ],
                      onChanged: (v) => setState(() => theme = v!),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Los permisos de notificación se administran por dispositivo.',
                    ),
                    if (error != null) MessageCard(error!, error: true),
                    if (message != null) MessageCard(message!),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(busy ? 'Guardando…' : 'Guardar cambios'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://harkai.lat/privacidad/'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Política de privacidad'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://harkai.lat/eliminar-cuenta/'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Solicitar eliminación de cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
