import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';

class AppDrawer extends StatelessWidget {
  final int section;
  final ValueChanged<int> onSelect;
  final VoidCallback onAccount;
  const AppDrawer({
    super.key,
    required this.section,
    required this.onSelect,
    required this.onAccount,
  });
  static const entries = [
    (Icons.map_outlined, 'Mi zona'),
    (Icons.shield_outlined, 'Reportes'),
    (Icons.pets_outlined, 'Mascotas'),
    (Icons.location_on_outlined, 'Lugares de ayuda'),
    (Icons.notifications_outlined, 'Mis alertas'),
    (Icons.history, 'Mis reportes'),
    (Icons.newspaper_outlined, 'Actualidad'),
    (Icons.help_outline, 'Ayuda'),
    (Icons.person_outline, 'Mi cuenta'),
  ];
  @override
  Widget build(BuildContext context) {
    final account = AppScope.of(context).account;
    return Drawer(
      backgroundColor: navy,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Image.asset('assets/icon/icon.png', width: 42, height: 42),
                  const SizedBox(width: 12),
                  const Text(
                    'harkai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'EL PULSO DE TU COMUNIDAD',
              style: TextStyle(
                color: Color(0xff8da7bb),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 25),
            ...entries.indexed.map(
              (entry) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selected: section == entry.$1,
                selectedTileColor: const Color(0xff173a39),
                selectedColor: green,
                textColor: const Color(0xffafc1ce),
                iconColor: const Color(0xffafc1ce),
                leading: Icon(entry.$2.$1, size: 21),
                title: Text(entry.$2.$2, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  onSelect(entry.$1);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(color: Color(0xff2b4356), height: 35),
            if (account != null)
              ListTile(
                textColor: Colors.white,
                title: Text(account.name),
                subtitle: Text(
                  account.role,
                  style: const TextStyle(color: Color(0xffafc1ce)),
                ),
              ),
            ListTile(
              textColor: green,
              iconColor: green,
              leading: Icon(account == null ? Icons.login : Icons.logout),
              title: Text(
                account == null ? 'Ingresar o crear cuenta' : 'Cerrar sesión',
              ),
              onTap: () {
                Navigator.pop(context);
                onAccount();
              },
            ),
            if (account?.role == 'gov' || account?.role == 'admin')
              ListTile(
                textColor: green,
                iconColor: green,
                leading: const Icon(Icons.open_in_new),
                title: const Text('Panel institucional web'),
                onTap: () => launchUrl(
                  Uri.parse('https://panel.harkai.lat/dashboard/gov'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
