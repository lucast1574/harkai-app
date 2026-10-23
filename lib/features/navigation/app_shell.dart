import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../account/profile_screen.dart';
import '../auth/login_screen.dart';
import '../help/help_screen.dart';
import '../help/support_place.dart';
import '../reports/quick_report_sheet.dart';
import '../reports/report_categories.dart';
import '../../core/models.dart';
import '../reports/report_browser.dart';
import '../reports/report_detail.dart';
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

  Future<bool> create({String? initialType, LatLng? initialPoint}) async {
    if (AppScope.of(context).account == null) {
      await login();
      if (!mounted || AppScope.of(context).account == null) return false;
    }
    final category = crimeTypes.contains(initialType)
        ? 'crime'
        : initialType ?? 'crime';
    final report = await showModalBottomSheet<Incident>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuickReportSheet(category: category),
    );
    if (mounted && report != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte publicado en tu ubicación.')),
      );
    }
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

  void openProfileOrLogin() {
    if (AppScope.of(context).account == null) {
      login();
    } else {
      setState(() => section = 8);
    }
  }

  Widget page() => switch (section) {
    1 => ReportBrowser(
      title: 'Reportes de la comunidad',
      onCreateReport: create,
    ),
    2 => ReportBrowser(
      title: 'Mascotas perdidas y encontradas',
      fixedType: 'pet',
      onCreateReport: create,
    ),
    3 => const ReportBrowser(
      title: 'Lugares de ayuda y salud',
      fixedType: 'place',
    ),
    4 => const ReportBrowser(title: 'Mis alertas', alerts: true),
    5 => ReportBrowser(
      title: 'Mis reportes',
      history: true,
      showMap: false,
      onCreateReport: create,
    ),
    6 => ReportBrowser(
      title: 'Actualidad de tu comunidad',
      showMap: false,
      onCreateReport: create,
    ),
    7 => const HelpScreen(),
    8 => const ProfileScreen(),
    _ => ReportBrowser(
      homeMode: true,
      onOpenDrawer: () => scaffold.currentState?.openDrawer(),
      onOpenProfile: openProfileOrLogin,
      onOpenHelp: () => setState(() => section = 7),
      onSelectSection: (value) => setState(() => section = value),
      onCreateReport: create,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.account;
    final support = app.pendingSupport;
    if (support != null && account != null && !app.loading) {
      app.pendingSupport = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && AppScope.of(context).account?.id == account.id) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => SafeArea(
              child: SingleChildScrollView(
                child: SupportPlaceDetails(place: support),
              ),
            ),
          );
        }
      });
    }
    final pending = app.pendingReport;
    if (pending != null && account != null && !app.loading) {
      app.pendingReport = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && AppScope.of(context).account?.id == account.id) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportDetail(id: pending)),
          );
        }
      });
    }

    final isHomeMap = section == 0 && !app.loading && app.error == null;

    return Scaffold(
      key: scaffold,
      appBar: isHomeMap
          ? null
          : AppBar(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              leading: IconButton(
                tooltip: 'Abrir menú lateral',
                onPressed: () => scaffold.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: green),
              ),
              title: Text(
                AppDrawer.entries[section].$2,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                if (section != 0)
                  IconButton(
                    tooltip: 'Volver al mapa',
                    onPressed: () => setState(() => section = 0),
                    icon: const Icon(Icons.map_outlined, color: green),
                  ),
                IconButton(
                  tooltip: 'Mi cuenta',
                  onPressed: openProfileOrLogin,
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
      drawer: AppDrawer(
        section: section,
        onSelect: (value) => setState(() => section = value),
        onAccount: () {
          account == null ? login() : logout();
        },
      ),
      body: isHomeMap
          ? KeyedSubtree(key: ValueKey('0:${account?.id}'), child: page())
          : SafeArea(
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
      floatingActionButton: isHomeMap || [3, 4, 7, 8].contains(section)
          ? null
          : FloatingActionButton.extended(
              heroTag: 'report',
              backgroundColor: green,
              foregroundColor: navy,
              onPressed: app.loading || app.error != null
                  ? null
                  : () => create(initialType: section == 2 ? 'pet' : null),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Reportar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
    );
  }
}
