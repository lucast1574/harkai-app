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

  Future<void> selectRadius(String value) async {
    if (value != 'custom') {
      setState(() => radius.text = value);
      return;
    }
    final radiusForm = GlobalKey<FormState>();
    var meters = radius.text;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: radiusForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: meters,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distancia en metros',
                    helperText: 'Entre 100 y 10 000 m',
                  ),
                  onChanged: (value) => meters = value,
                  validator: (value) {
                    final distance = int.tryParse(value ?? '');
                    return distance == null ||
                            distance < 100 ||
                            distance > 10000
                        ? 'Elige de 100 a 10 000 metros.'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (radiusForm.currentState!.validate()) {
                        Navigator.pop(context, meters);
                      }
                    },
                    child: const Text('Usar esta distancia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && selected != null) setState(() => radius.text = selected);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).account;
    if (user == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final roleLabel = switch (user.role) {
      'admin' => 'Administrador',
      'gov' => 'Gestión municipal',
      _ => 'Miembro de la comunidad',
    };
    final radiusOptions = <String, String>{
      '500': '500 m',
      '1000': '1 km',
      '2500': '2,5 km',
      '5000': '5 km',
      '10000': '10 km',
      if (!['500', '1000', '2500', '5000', '10000'].contains(radius.text))
        radius.text: '${radius.text} m',
      'custom': 'Otra distancia…',
    };
    return Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(child: AccountAvatar(account: user, radius: 38)),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              roleLabel,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text(
                'Datos personales',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(user.name),
              childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                AppField(
                  label: 'Tu nombre',
                  controller: name,
                  maxLength: 80,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Escribe al menos dos caracteres.'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 21),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu zona, a tu medida',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppChoiceField(
                    label: 'Alertas que te interesan',
                    value: notifications,
                    options: const {
                      'all': 'Todas las alertas',
                      'critical': 'Emergencias y seguridad',
                      'none': 'Ninguna',
                    },
                    onChanged: (value) => setState(() => notifications = value),
                  ),
                  const SizedBox(height: 14),
                  AppChoiceField(
                    label: 'Cerca de ti',
                    value: radius.text,
                    options: radiusOptions,
                    onChanged: selectRadius,
                  ),
                  const SizedBox(height: 14),
                  AppChoiceField(
                    label: 'Apariencia',
                    value: theme,
                    options: const {
                      'system': 'Como mi teléfono',
                      'light': 'Clara',
                      'dark': 'Oscura',
                    },
                    onChanged: (value) => setState(() => theme = value),
                  ),
                  if (error != null) MessageCard(error!, error: true),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Cambios guardados',
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(busy ? 'Guardando…' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NotificationSettings(key: ValueKey(user.id)),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.credit_card_off_rounded),
            title: const Text('Bloquear tarjetas'),
            subtitle: const Text('Línea 1820'),
            trailing: const Icon(Icons.call_outlined, size: 20),
            onTap: () => launchUrl(Uri(scheme: 'tel', path: '1820')),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Cerrar sesión'),
            onTap: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await AppScope.of(context).logout();
                    } catch (e) {
                      if (mounted) setState(() => error = e.toString());
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
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
      ),
    );
  }
}
