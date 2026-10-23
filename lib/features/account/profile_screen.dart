import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
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
        // Navy Hero Card (Restored & modernized from affaab0 Profile)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: green,
                child: Text(
                  user.name.trim().isNotEmpty
                      ? user.name.trim()[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  color: green,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Color(0xffcbd5e1), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick Card Block Emergency Button (1820 - from affaab0 Profile!)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: '1820')),
                  icon: const Icon(Icons.credit_card_off_rounded, size: 18),
                  label: const Text('Bloquear tarjetas por robo (1820)'),
                ),
              ),
            ],
          ),
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
                  DropdownButtonFormField<String>(
                    borderRadius: BorderRadius.circular(16),
                    initialValue: notifications,
                    decoration: const InputDecoration(
                      labelText: 'Qué alertas recibir',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Todas, incluidas las no verificadas'),
                      ),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Solo emergencias y seguridad'),
                      ),
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('Desactivadas'),
                      ),
                    ],
                    onChanged: (v) => setState(() => notifications = v!),
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
