import '../notifications/notification_permissions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import '../../shared/account_avatar.dart';
import 'appearance_picker.dart';
import '../help/safety_report.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  bool initialized = false, busy = false;
  String? error, message;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      final user = AppScope.of(context).account;
      if (user != null) {
        name.text = user.name;
        initialized = true;
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> saveName() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    final app = AppScope.of(context);
    try {
      await app.api.request('PATCH', 'me', body: {'name': name.text.trim()});
      await app.reloadAccount();
      if (mounted) setState(() => message = 'Nombre guardado.');
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> appearance(String value) async {
    try {
      await AppScope.of(context).changeAppearance(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El tema se aplicó en este teléfono. Se sincronizará cuando vuelvas a elegirlo con conexión.',
            ),
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    setState(() => busy = true);
    try {
      await AppScope.of(context).logout();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.account;
    if (user == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(child: AccountAvatar(account: user, radius: 36)),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Datos personales'),
              subtitle: Text(user.name),
              childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                AppField(
                  label: 'Tu nombre',
                  controller: name,
                  maxLength: 80,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Escribe al menos dos caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: busy ? null : saveName,
                    child: const Text('Guardar nombre'),
                  ),
                ),
                if (message != null) Text(message!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppearancePicker(
            value: app.appearance ?? user.preferences.theme,
            onChanged: appearance,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.phonelink_setup_rounded),
            title: const Text('Permisos del teléfono'),
            subtitle: const Text('Ubicación, avisos y batería'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationPermissions(),
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.credit_card_off_rounded),
            title: const Text('Bloquear tarjetas'),
            subtitle: const Text('Línea 1820'),
            trailing: const Icon(Icons.call_outlined, size: 20),
            onTap: () => launchUrl(Uri(scheme: 'tel', path: '1820')),
          ),
          const SafetyReportButton(),
          if (error != null) MessageCard(error!, error: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
                backgroundColor: colors.error.withValues(alpha: .09),
                foregroundColor: colors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: busy ? null : logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                busy ? 'Cerrando sesión…' : 'Cerrar sesión',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
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
                  Uri.parse('https://harkai.lat/terminos/'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Términos'),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://panel.harkai.lat/eliminar-cuenta'),
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
