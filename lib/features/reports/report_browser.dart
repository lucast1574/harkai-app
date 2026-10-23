import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../help/coverage_notice.dart';
import '../help/emergency_sheet.dart';
import '../help/district_directory.dart';
import '../help/nearby_support_card.dart';
import '../help/support_place.dart';
import '../help/support_place_list.dart';
import '../help/support_proximity.dart';
import '../help/support_proximity_notice.dart';
import '../location/foreground_location.dart';
import '../map/community_map.dart';
import 'report_detail.dart';
import 'report_repository.dart';
import 'report_tile.dart';
import 'map_report_sheet.dart';
import 'report_categories.dart';

class ReportBrowser extends StatefulWidget {
  final String title, fixedType;
  final bool history, alerts, showMap, homeMode;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHelp;
  final ValueChanged<int>? onSelectSection;
  final Future<bool> Function({String? initialType, LatLng? initialPoint})?
  onCreateReport;

  const ReportBrowser({
    super.key,
    this.title = 'El pulso de tu zona',
    this.fixedType = '',
    this.history = false,
    this.alerts = false,
    this.showMap = true,
    this.homeMode = false,
    this.onOpenDrawer,
    this.onOpenProfile,
    this.onOpenHelp,
    this.onSelectSection,
    this.onCreateReport,
  });

  @override
  State<ReportBrowser> createState() => _ReportBrowserState();
}

class _ReportBrowserState extends State<ReportBrowser> {
  bool? covered;
  String? coverageError;
  LatLng? userPosition;
  double userAccuracy = 1000;
  DateTime? positionTime;
  ForegroundLocation? location;
  SupportProximityNotice? supportNotice;

  bool get supportEnabled =>
      widget.showMap &&
      !widget.history &&
      !widget.alerts &&
      (widget.fixedType.isEmpty || widget.fixedType == 'place');

  List<NearbySupport> get nearby =>
      userPosition == null ||
          positionTime == null ||
          DateTime.now().difference(positionTime!) > const Duration(minutes: 2)
      ? []
      : nearbySupport(supportPlaces, userPosition!, accuracy: userAccuracy);

  LatLng center = const LatLng(-12.0464, -77.0428);
  String cityName = 'Lima y Callao';
  int radius = 50000;
  String type = '';
  List<Incident> items = [];
  List<SupportPlace> supportPlaces = [];
  String? supportError;
  String? cursor, error;
  bool busy = false, initialized = false;
  int generation = 0;
  int focusRequest = 0;
  Timer? refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      location = ForegroundLocation(
        track: supportEnabled,
        onPosition: acceptPosition,
        onError: (e) {
          if (mounted) setState(() => error = e.toString());
          return false;
        },
      );
      type = widget.fixedType;
      if (widget.homeMode) {
        refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          if (mounted &&
              !busy &&
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed) {
            load(background: true);
          }
        });
      }
      Future.microtask(() async {
        unawaited(load());
        if (supportEnabled) await location!.start();
      });
    }
  }

  Future<int> load({bool more = false, bool background = false}) async {
    if (!mounted) return 0;
    final version = ++generation;
    setState(() {
      busy = true;
      error = null;
      if (!more && !background) {
        items = [];
        cursor = null;
      }
    });
    final supportLoad = supportEnabled && !more && !background
        ? loadSupport(version)
        : Future.value(0);
    if (widget.fixedType == 'place') {
      await supportLoad;
      if (mounted && version == generation) setState(() => busy = false);
      return 0;
    }
    try {
      final page = await ReportRepository(AppScope.of(context).api).list(
        latitude: center.latitude,
        longitude: center.longitude,
        radius: radius,
        type: type,
        cursor: more ? cursor : null,
        history: widget.history,
        alerts: widget.alerts,
      );
      if (mounted && version == generation) {
        setState(() {
          items = more
              ? {
                  for (final i in [...items, ...page.items]) i.id: i,
                }.values.toList()
              : page.items;
          cursor = page.cursor;
        });
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && version == generation) setState(() => busy = false);
    }
    await supportLoad;
    return items.length;
  }

  Future<int> loadSupport(int version) async {
    if (!mounted || version != generation) return 0;
    setState(() {
      supportError = null;
    });
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'support/places?lat=${center.latitude}&lng=${center.longitude}&radius_meters=$radius',
        authenticated: false,
      );
      if (mounted && version == generation) {
        setState(
          () => supportPlaces = (data['items'] as List)
              .map((p) => SupportPlace.fromJson(p as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(
          () => supportError =
              'No se pudo cargar el directorio de salud. Las alertas siguen disponibles.',
        );
      }
    }
    if (mounted && version == generation && supportError == null) {
      final app = AppScope.of(context);
      supportNotice ??= SupportProximityNotice(
        app.api,
        app.notifications.display,
        () => app.account?.id,
      );
      await supportNotice!.notify(
        nearby,
        enabled:
            (location?.active ?? false) &&
            app.notifications.enabled &&
            app.account?.preferences.notifications != 'none',
      );
    }
    return supportPlaces.length;
  }

  Future<bool> locate() async {
    final located = await location!.start(requestPermission: true);
    if (mounted && located && userPosition != null) {
      setState(() {
        center = userPosition!;
        focusRequest++;
      });
    }
    return located;
  }

  Future<bool> acceptPosition(Position p) async {
    if (!mounted) return false;
    setState(() {
      covered = null;
      coverageError = null;
      userPosition = LatLng(p.latitude, p.longitude);
      userAccuracy = p.accuracy;
      positionTime = p.timestamp;
      if (p.accuracy <= 250) {
        center = userPosition!;
        cityName = p.latitude > -9.5 ? 'Trujillo · Mi zona' : 'Lima · Mi zona';
      }
    });
    if (p.accuracy <= 250) await Future.wait([load(), loadCoverage(p)]);
    return true;
  }

  Future<bool> loadCoverage(Position position) async {
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'support/coverage?lat=${position.latitude}&lng=${position.longitude}',
        authenticated: false,
      );
      if (mounted && positionTime == position.timestamp) {
        setState(() {
          covered = data['covered'] as bool;
          coverageError = null;
        });
      }
      return data['covered'] as bool;
    } catch (_) {
      if (mounted && positionTime == position.timestamp) {
        setState(() {
          covered = null;
          coverageError = 'unavailable';
        });
      }
      return false;
    }
  }

  void switchCity(String cityKey) {
    setState(() {
      if (cityKey == 'trujillo') {
        center = const LatLng(-8.1116, -79.0287);
        cityName = 'Trujillo';
      } else {
        center = const LatLng(-12.0464, -77.0428);
        cityName = 'Lima y Callao';
      }
      radius = 50000;
    });
    load();
  }

  void showZoneSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar zona en el mapa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Visualiza todos los reportes activos de la ciudad o usa tu GPS.',
                style: TextStyle(fontSize: 13, color: Color(0xff64748b)),
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(
                  backgroundColor: green,
                  child: Icon(Icons.my_location_rounded, color: navy),
                ),
                title: const Text(
                  'Usar mi ubicación GPS actual',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Centrar el mapa donde te encuentras'),
                onTap: () {
                  Navigator.pop(ctx);
                  locate();
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(
                  backgroundColor: navy,
                  child: Icon(Icons.location_city_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Lima y Callao',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Ver todos los reportes de Lima Metropolitana',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  switchCity('lima');
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(
                  backgroundColor: navy,
                  child: Icon(Icons.location_city_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Trujillo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Ver todos los reportes de Trujillo'),
                onTap: () {
                  Navigator.pop(ctx);
                  switchCity('trujillo');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showEmergencyDialer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => EmergencySheet(
        latitude: userPosition?.latitude,
        longitude: userPosition?.longitude,
      ),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    location?.dispose();
    super.dispose();
  }

  Future<bool> open(Incident i) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetail(id: i.id, own: widget.history),
      ),
    );
    if (mounted) await load();
    return true;
  }

  Future<void> triggerCreate({String? categoryId, LatLng? initialPoint}) async {
    if (widget.onCreateReport != null) {
      await widget.onCreateReport!(
        initialType: categoryId,
        initialPoint: initialPoint ?? userPosition ?? center,
      );
      if (mounted) await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeMode) {
      return _buildHomeMapExperience(context);
    }
    return _buildSecondaryFeedExperience(context);
  }

  Widget _buildHomeMapExperience(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.account;

    return Stack(
      children: [
        // 1. Full-screen Interactive Map (Long-press to leave a report at that point -> requires login!)
        Positioned.fill(
          child: CommunityMap(
            fullScreen: true,
            focusRequest: focusRequest,
            userPositionFresh:
                positionTime != null &&
                DateTime.now().difference(positionTime!) <
                    const Duration(minutes: 2),
            center: center,
            userPosition: userPosition,
            incidents: items,
            supportPlaces: supportPlaces,
            onReport: open,
            onLongPressPoint: (point) => triggerCreate(
              categoryId: type.isNotEmpty ? type : null,
              initialPoint: point,
            ),
          ),
        ),

        // 2. Top Floating Header Pill + Category Filter Strip
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HomeHeaderWidget Pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Harkai Shield / Menu Button
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: widget.onOpenDrawer,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: navy,
                                  radius: 22,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    height: 34,
                                    errorBuilder: (_, _, _) => Image.asset(
                                      'assets/icon/icon.png',
                                      height: 30,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.shield_rounded,
                                        color: green,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      color: green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_rounded,
                                      size: 11,
                                      color: navy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center: Active Zone / City + "Monitoreando tu zona"
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: showZoneSelector,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          cityName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: navy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: navy,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xff16a34a),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          busy
                                              ? 'Actualizando tu zona…'
                                              : '${items.length} alertas · actualización automática',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xff166534),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Right: User Profile Avatar Button
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: widget.onOpenProfile,
                            child: CircleAvatar(
                              radius: 21,
                              backgroundColor: account != null
                                  ? green
                                  : const Color(0xffe2e8f0),
                              child: account != null
                                  ? Text(
                                      account.name.trim().isNotEmpty
                                          ? account.name.trim()[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: navy,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.account_circle,
                                      color: navy,
                                      size: 36,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Horizontal Filter Chips on the Map (without 'place')
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      _MapFilterPill(
                        label: 'Todas (${items.length})',
                        selected: type.isEmpty,
                        color: navy,
                        onTap: () {
                          setState(() => type = '');
                          load();
                        },
                      ),
                      ...mapReportTypes.map((catId) {
                        final vis = categoryVisual(catId);
                        return _MapFilterPill(
                          label: vis.shortLabel,
                          selected: type == catId,
                          color: vis.color,
                          type: catId,
                          onTap: () {
                            setState(() => type = type == catId ? '' : catId);
                            load();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Right-Side Map Controls (GPS, Health Layer, Refresh)
        Positioned(
          right: 14,
          top: MediaQuery.of(context).padding.top + 124,
          child: Column(
            children: [
              _FloatingMapControlButton(
                tooltip: 'Centrar en mi ubicación GPS',
                icon: Icons.my_location_rounded,
                active: userPosition != null,
                onTap: locate,
              ),
            ],
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: MapReportSheet(
            onReport: (category) => triggerCreate(categoryId: category),
            onEmergency: showEmergencyDialer,
            onHelp: () => widget.onOpenHelp?.call(),
            children: [
              if (app.loading) const LinearProgressIndicator(minHeight: 2),
              if (app.error != null)
                MessageCard(
                  'No se pudo actualizar la conexión. Puedes seguir explorando el mapa.',
                  error: true,
                  onRetry: app.initialize,
                ),
              if (error != null)
                MessageCard(error!, error: true, onRetry: () => load()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryFeedExperience(BuildContext context) {
    final app = AppScope.of(context);
    final isPlacesDirectory = widget.fixedType == 'place';
    final isPetsSection = widget.fixedType == 'pet';

    return RefreshIndicator(
      onRefresh: () async {
        await load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          PageHeading(
            widget.title,
            isPlacesDirectory
                ? 'Directorio permanente de centros de salud y contactos municipales en el mapa.'
                : widget.history
                ? 'Tus publicaciones enviadas a la comunidad.'
                : widget.alerts
                ? 'Alertas cercanas según tu radio y preferencias.'
                : 'Reportes comunitarios en tiempo real en tu ciudad.',
          ),

          // Quick Zone & GPS Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text('Mi ubicación GPS'),
                  onPressed: busy ? null : locate,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Lima y Callao'),
                  selected: cityName.startsWith('Lima'),
                  onSelected: busy ? null : (_) => switchCity('lima'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Trujillo'),
                  selected: cityName.startsWith('Trujillo'),
                  onSelected: busy ? null : (_) => switchCity('trujillo'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: busy ? null : () => load(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips (when not locked to fixedType, excluding 'place')
          if (widget.fixedType.isEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todas'),
                      selected: type.isEmpty,
                      onSelected: busy
                          ? null
                          : (_) {
                              setState(() => type = '');
                              load();
                            },
                    ),
                  ),
                  ...app.categories
                      .where((c) => c.id != 'place')
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.label),
                            selected: type == c.id,
                            onSelected: busy
                                ? null
                                : (_) {
                                    setState(
                                      () => type = type == c.id ? '' : c.id,
                                    );
                                    load();
                                  },
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Map Preview Card
          if (widget.showMap) ...[
            SizedBox(
              height: 250,
              child: CommunityMap(
                center: center,
                userPosition: userPosition,
                incidents: items,
                supportPlaces: supportPlaces,
                onReport: open,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Dedicated Action Button ONLY for Pets (Places are permanent on the map!)
          if (isPetsSection && widget.onCreateReport != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => triggerCreate(categoryId: 'pet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryVisual('pet').color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                icon: const CategoryGlyph(
                  type: 'pet',
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  'Reportar mascota perdida o encontrada',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (isPlacesDirectory)
            DistrictDirectory(onCityChange: (city) => switchCity(city)),
          if (supportEnabled)
            CoverageNotice(covered: covered, error: coverageError),
          if (supportEnabled) NearbySupportCard(nearby: nearby),
          if (supportError != null) MessageCard(supportError!, error: true),
          if (isPlacesDirectory && supportPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Centros de salud permanentes (${supportPlaces.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SupportPlaceList(places: supportPlaces),
          ],
          if (error != null)
            MessageCard(error!, error: true, onRetry: () => load()),
          if (!isPlacesDirectory) ...[
            const SizedBox(height: 12),
            Text(
              '${items.length} reportes en esta vista${cursor != null ? ' · hay más resultados' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...items.map((i) => ReportTile(incident: i, onTap: () => open(i))),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!busy && error == null && items.isEmpty)
              const MessageCard(
                'Aún no hay reportes en esta consulta. Puedes cambiar de ciudad o publicar un nuevo reporte.',
              ),
            if (cursor != null)
              OutlinedButton(
                onPressed: busy ? null : () => load(more: true),
                child: const Text('Cargar más reportes'),
              ),
          ],
        ],
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  final String label;
  final String? type;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _MapFilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected ? color : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type != null) ...[
                  CategoryGlyph(
                    type: type!,
                    size: 14,
                    color: selected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingMapControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;

  final VoidCallback onTap;
  const _FloatingMapControlButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? navy : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: active ? Colors.white : navy),
          ),
        ),
      ),
    );
  }
}
