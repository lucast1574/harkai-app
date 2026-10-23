import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../../shared/app_choice_field.dart';
import '../../shared/account_avatar.dart';
import '../notifications/notification_settings.dart';

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
    if (user == null) return const SizedBox.shrink();
    final roleLabel = switch (user.role) {
      'admin' => 'Administrador',
      'gov' => 'Gestión municipal',
      _ => 'Vecino verificado',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          children: [
            AccountAvatar(account: user, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.credit_card_off_rounded),
          title: const Text('Bloquear tarjetas por robo'),
          subtitle: const Text('Línea 1820'),
          trailing: const Icon(Icons.call_outlined),
          onTap: () => launchUrl(Uri(scheme: 'tel', path: '1820')),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus datos y preferencias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppField(
                    label: 'Nombre visible en tu cuenta',
                    controller: name,
                    maxLength: 80,
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Escribe al menos dos caracteres.'
                        : null,
                  ),
                  AppChoiceField(
                    label: 'Qué alertas recibir',
                    value: notifications,
                    options: const {
                      'all': 'Todas, incluidas las no verificadas',
                      'critical': 'Solo emergencias y seguridad',
                      'none': 'Desactivadas',
                    },
                    onChanged: (value) => setState(() => notifications = value),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Radio de notificaciones cercanas',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [500, 1000, 2500, 5000, 10000].map((preset) {
                      final active = int.tryParse(radius.text) == preset;
                      return ChoiceChip(
                        label: Text(
                          preset < 1000 ? '$preset m' : '${preset ~/ 1000} km',
                        ),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => radius.text = '$preset'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  AppField(
                    label: 'Radio personalizado (100 a 10000 m)',
                    controller: radius,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final r = int.tryParse(v ?? '');
                      return r == null || r < 100 || r > 10000
                          ? 'Elige de 100 a 10000 metros.'
                          : null;
                    },
                  ),
                  const Text(
                    'Tema de la aplicación',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final opt in [
                        ('system', 'Sistema'),
                        ('light', 'Claro'),
                        ('dark', 'Oscuro'),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  opt.$2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: theme == opt.$1,
                              onSelected: (_) => setState(() => theme = opt.$1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    MessageCard(error!, error: true),
                  ],
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    MessageCard(message!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(busy ? 'Guardando…' : 'Guardar preferencias'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        NotificationSettings(key: ValueKey(user.id)),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Cerrar sesión'),
          onTap: () async {
            await AppScope.of(context).logout();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://harkai.lat/privacidad/'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Privacidad'),
            ),
            const Text('·'),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://harkai.lat/eliminar-cuenta/'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Eliminar cuenta'),
            ),
          ],
        ),
      ],
    );
  }
}
