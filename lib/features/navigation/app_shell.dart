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
import 'app_destinations.dart';
import '../business/business_directory.dart';
import '../business/business_point.dart';
import '../map/map_target.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final scaffold = GlobalKey<ScaffoldState>();
  int section = 0;
  MapTarget? mapTarget;
  void showOnMap(MapTarget target) {
    setState(() {
      mapTarget = target;
      section = 0;
      sectionHistory.clear();
    });
  }

  final sectionHistory = <int>[];

  void selectSection(int value) {
    if (value == section) return;
    setState(() {
      if (value == 0) {
        sectionHistory.clear();
      } else {
        sectionHistory.add(section);
      }
      section = value;
    });
  }

  void handleBack() {
    if (scaffold.currentState?.isDrawerOpen == true) {
      scaffold.currentState?.closeDrawer();
      return;
    }
    if (sectionHistory.isNotEmpty) {
      setState(() => section = sectionHistory.removeLast());
    } else if (section != 0) {
      setState(() => section = 0);
    }
  }

  void openDestinations() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: [
            const ListTile(
              title: Text(
                'Explora Harkai',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            for (final index in [2, 3, 4, 5])
              ListTile(
                leading: Icon(AppDestinations.entries[index].$1),
                title: Text(AppDestinations.entries[index].$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  selectSection(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> login() async {
    final app = AppScope.of(context);
    if (app.loading) await app.initialize();
    if (!mounted) return false;
    if (app.account != null) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return mounted && app.account != null;
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

  Future<void> openProfileOrLogin() async {
    if (AppScope.of(context).account == null) {
      if (!await login()) return;
    }
    if (mounted) selectSection(6);
  }

  Widget page() => switch (section) {
    1 => ReportBrowser(
      title: 'Reportes de la comunidad',
      showMap: false,
      onMapTarget: showOnMap,
    ),
    2 => ReportBrowser(
      title: 'Mascotas perdidas y encontradas',
      fixedType: 'pet',
      showMap: false,
      onMapTarget: showOnMap,
    ),
    3 => ReportBrowser(
      title: 'Lugares de ayuda y salud',
      fixedType: 'place',
      showMap: false,
      onMapTarget: showOnMap,
    ),
    4 => BusinessDirectory(onMap: showOnMap),
    5 => const HelpScreen(),
    6 => const ProfileScreen(),
    _ => homeMap(),
  };

  Widget homeMap() => ReportBrowser(
    mapTarget: mapTarget,
    homeMode: true,
    onOpenDrawer: openDestinations,
    onOpenProfile: openProfileOrLogin,
    onOpenHelp: () => selectSection(5),
    onSelectSection: selectSection,
    onCreateReport: create,
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.account;
    final business = app.pendingBusiness;
    if (business != null && account != null && !app.loading) {
      app.pendingBusiness = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final data = await app.api.request("GET", "businesses/$business");
          if (mounted && app.account?.id == account.id) {
            showOnMap(MapTarget.business(BusinessPoint(data)));
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text("Este negocio ya no está disponible."),
              ),
            );
          }
        }
      });
    }
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

    final isHomeMap = section == 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) handleBack();
      },
      child: Scaffold(
        key: scaffold,
        appBar: isHomeMap
            ? null
            : AppBar(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                leading: IconButton(
                  tooltip: 'Volver',
                  onPressed: handleBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Explorar',
                    onPressed: openDestinations,
                    icon: const Icon(Icons.apps_rounded),
                  ),
                ],
                title: Text(
                  AppDestinations.entries[section].$2,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        body: isHomeMap
            ? KeyedSubtree(key: const ValueKey('home-map'), child: homeMap())
            : SafeArea(
                child: account == null && [6].contains(section)
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: switch (section) {
            0 => 0,
            6 => 0,
            _ => 1,
          },
          onDestinationSelected: (index) => selectSection([0, 1][index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_agenda_outlined),
              selectedIcon: Icon(Icons.view_agenda_rounded),
              label: 'Comunidad',
            ),
          ],
        ),
      ),
    );
  }
}
