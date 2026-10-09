import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../reports/report_browser.dart';
import '../reports/create_report.dart';
import '../auth/login_screen.dart';
import '../account/profile_screen.dart';
import '../help/help_screen.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final scaffold = GlobalKey<ScaffoldState>();
  int section = 0;
  Future<bool> login() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return true;
  }

  Future<bool> create() async {
    if (AppScope.of(context).account == null) {
      await login();
      if (!mounted || AppScope.of(context).account == null) return false;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReport()),
    );
    return true;
  }

  Future<bool> logout() async {
    try {
      await AppScope.of(context).logout();
      if (mounted) {
        setState(() {
          section = 0;
        });
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return false;
    }
  }

  Widget page() => switch (section) {
    1 => const ReportBrowser(title: 'Reportes de la comunidad'),
    2 => const ReportBrowser(
      title: 'Mascotas perdidas y encontradas',
      fixedType: 'pet',
    ),
    3 => const ReportBrowser(title: 'Lugares de ayuda', fixedType: 'place'),
    4 => const ReportBrowser(title: 'Mis alertas', alerts: true),
    5 => const ReportBrowser(
      title: 'Mis reportes',
      history: true,
      showMap: false,
    ),
    6 => const ReportBrowser(
      title: 'Actualidad de tu comunidad',
      showMap: false,
    ),
    7 => const HelpScreen(),
    8 => const ProfileScreen(),
    _ => const ReportBrowser(),
  };
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.account;
    return Scaffold(
      key: scaffold,
      drawer: AppDrawer(
        section: section,
        onSelect: (value) => setState(() => section = value),
        onAccount: () {
          account == null ? login() : logout();
        },
      ),
      body: SafeArea(
        child: app.loading
            ? const Center(child: CircularProgressIndicator())
            : app.error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const PageHeading(
                      'Conectemos tu comunidad',
                      'El mapa y los reportes se consultan en Harkai.',
                    ),
                    MessageCard(
                      app.error!,
                      error: true,
                      onRetry: app.initialize,
                    ),
                  ],
                ),
              )
            : account == null && [4, 5, 8].contains(section)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PageHeading(
                        'Una cuenta para tu comunidad',
                        'Ingresa para guardar tus preferencias y ver tus reportes.',
                      ),
                      FilledButton(
                        onPressed: login,
                        child: const Text('Ingresar o crear cuenta'),
                      ),
                    ],
                  ),
                ),
              )
            : KeyedSubtree(
                key: ValueKey('$section:${account?.id}'),
                child: page(),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.small(
              heroTag: 'menu',
              tooltip: 'Abrir menú lateral',
              backgroundColor: navy,
              foregroundColor: green,
              onPressed: () => scaffold.currentState?.openDrawer(),
              child: const Icon(Icons.menu),
            ),
            FloatingActionButton.extended(
              heroTag: 'report',
              backgroundColor: green,
              foregroundColor: navy,
              onPressed: app.loading || app.error != null ? null : create,
              icon: const Icon(Icons.add),
              label: const Text('Reportar'),
            ),
          ],
        ),
      ),
    );
  }
}
