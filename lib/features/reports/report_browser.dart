import 'dart:async';
import '../map/map_target.dart';
import '../business/business_point.dart';
import '../../shared/app_choice_field.dart';
import 'report_categories.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../map/map_location_header.dart';
import '../map/map_category_filters.dart';
import '../help/coverage_notice.dart';
import '../help/emergency_sheet.dart';
import '../help/nearby_support_card.dart';
import '../help/support_place.dart';
import '../help/support_place_list.dart';
import '../help/support_proximity.dart';
import '../help/support_proximity_notice.dart';
import '../location/foreground_location.dart';
import '../location/location_service.dart';
import '../map/community_map.dart';
import 'report_detail.dart';
import 'report_repository.dart';
import 'report_tile.dart';
import 'map_report_sheet.dart';

class ReportBrowser extends StatefulWidget {
  final String title, fixedType;
  final MapTarget? mapTarget;
  final ValueChanged<MapTarget>? onMapTarget;
  final bool history, alerts, showMap, homeMode;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHelp;
  final ValueChanged<int>? onSelectSection;
  final Future<bool> Function({String? initialType, LatLng? initialPoint})?
  onCreateReport;

  const ReportBrowser({
    super.key,
    this.mapTarget,
    this.onMapTarget,
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
  MapTarget? selectedTarget;
  bool ownOnly = false;
  @override
  void initState() {
    super.initState();
    selectedTarget = widget.mapTarget;
  }

  @override
  void didUpdateWidget(covariant ReportBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapTarget != widget.mapTarget) {
      selectedTarget = widget.mapTarget;
    }
  }

  bool? covered;
  String? coverageError;
  LatLng? userPosition;
  LatLng? cachedPosition;
  double userAccuracy = 1000;
  String? districtName, provinceName;
  LatLng? resolvedPoint;
  DateTime? districtTime;
  int districtGeneration = 0;
  DateTime? positionTime;
  ForegroundLocation? location;
  SupportProximityNotice? supportNotice;

  bool get supportEnabled =>
      (widget.homeMode || widget.fixedType == 'place') &&
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
  int radius = 1000;
  String type = '';
  List<BusinessPoint> businesses = [];
  List<Incident> items = [];
  List<SupportPlace> supportPlaces = [];
  String? supportError;
  String? cursor, error;
  bool busy = false, initialized = false;
  int generation = 0;
  int supportGeneration = 0;
  static const supportRadius = 5000;
  int focusRequest = 0;
  bool focusedOnArrival = false;
  bool locating = false;
  double sheetExtent = .16;
  Timer? refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      location = ForegroundLocation(
        track: !widget.history,
        onPosition: acceptPosition,
        onCachedPosition: acceptCachedPosition,
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
        if (!widget.history) {
          await location!.start(requestPermission: widget.homeMode);
        }
      });
    }
  }

  Future<int> load({bool more = false, bool background = false}) async {
    if (!mounted ||
        (!widget.history &&
            !ownOnly &&
            userPosition == null &&
            cachedPosition == null)) {
      return 0;
    }
    final version = ++generation;
    setState(() {
      busy = true;
      error = null;
      if (!more && !background) {
        items = [];
        cursor = null;
      }
    });
    final supportLoad = supportEnabled && !more
        ? loadSupport()
        : Future.value(0);
    if (widget.fixedType == 'place') {
      await supportLoad;
      if (mounted && version == generation) setState(() => busy = false);
      return 0;
    }
    try {
      if (widget.homeMode) unawaited(loadBusinesses(version));
      if (!mounted || version != generation) return 0;
      final page = await ReportRepository(AppScope.of(context).api).list(
        latitude: center.latitude,
        longitude: center.longitude,
        radius: radius,
        type: type,
        cursor: more ? cursor : null,
        history: widget.history || ownOnly,
        archive: !widget.homeMode && !ownOnly,
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

  Future<void> loadBusinesses(int version) async {
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'businesses?lat=${center.latitude}&lng=${center.longitude}&radius_meters=$radius&limit=100',
        authenticated: false,
      );
      if (mounted && version == generation) {
        setState(
          () => businesses = (data['items'] as List)
              .map((p) => BusinessPoint(p as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (_) {
      /* Independent of community alerts. */
    }
  }

  Future<int> loadSupport() async {
    if (!mounted) return 0;
    final version = ++supportGeneration;
    setState(() {
      supportError = null;
    });
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'support/places?lat=${center.latitude}&lng=${center.longitude}&radius_meters=$supportRadius',
        authenticated: false,
      );
      if (mounted && version == supportGeneration) {
        setState(
          () => supportPlaces = (data['items'] as List)
              .map((p) => SupportPlace.fromJson(p as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted && version == supportGeneration) {
        setState(
          () => supportError =
              'No se pudo cargar el directorio de salud. Las alertas siguen disponibles.',
        );
      }
    }
    if (mounted && version == supportGeneration && supportError == null) {
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
    if (locating) return false;
    setState(() => locating = true);
    try {
      final position = await currentLocation();
      if (!mounted) return false;
      await acceptPosition(position);
      if (!mounted) return false;
      setState(() {
        center = userPosition!;
        focusRequest++;
      });
      return true;
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
      return false;
    } finally {
      if (mounted) setState(() => locating = false);
    }
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
        if (widget.homeMode && !focusedOnArrival) {
          focusedOnArrival = true;
          focusRequest++;
        }
      }
    });
    if (p.accuracy <= 250) {
      unawaited(
        Future.wait([load(background: true), loadCoverage(p), loadDistrict(p)]),
      );
    }
    return true;
  }

  Future<bool> acceptCachedPosition(Position p) async {
    if (!mounted || userPosition != null) return false;
    setState(() {
      cachedPosition = LatLng(p.latitude, p.longitude);
      center = cachedPosition!;
      focusRequest++;
    });
    // Public nearby data may use this camera position. Proximity notifications
    // continue to require userPosition, accuracy and a fresh timestamp.
    unawaited(load());
    return true;
  }

  Future<bool> loadDistrict(Position position) async {
    final point = LatLng(position.latitude, position.longitude);
    if (resolvedPoint != null &&
        districtTime != null &&
        const Distance()(resolvedPoint!, point) < 150 &&
        DateTime.now().difference(districtTime!) <
            const Duration(minutes: 10)) {
      return true;
    }
    final version = ++districtGeneration;
    if (mounted) {
      setState(() {
        districtName = null;
        provinceName = null;
        resolvedPoint = null;
        districtTime = null;
      });
    }
    try {
      final result = await AppScope.of(context).api.request(
        'GET',
        'geo/district?lat=${position.latitude}&lng=${position.longitude}',
        authenticated: false,
      );
      final district = result['district'] as Map<String, dynamic>;
      final name = district['name'] as String;
      final province = district['province'] as String;
      if (!mounted || version != districtGeneration) return false;
      setState(() {
        districtName = name;
        provinceName = province;
        resolvedPoint = point;
        districtTime = DateTime.now();
      });
      return true;
    } catch (_) {
      return false;
    }
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
        builder: (_) => ReportDetail(
          id: i.id,
          own: widget.history || ownOnly,
          onMap: widget.onMapTarget == null
              ? null
              : (report) {
                  Navigator.pop(context);
                  widget.onMapTarget!(MapTarget.report(report));
                },
        ),
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
    return Stack(
      children: [
        Positioned.fill(
          child: CommunityMap(
            fullScreen: true,
            focusRequest: focusRequest,
            bottomObstruction: sheetExtent * MediaQuery.sizeOf(context).height,
            topObstruction: MediaQuery.paddingOf(context).top + 132,
            userPositionFresh:
                positionTime != null &&
                DateTime.now().difference(positionTime!) <
                    const Duration(minutes: 2),
            center: center,
            userPosition: userPosition ?? cachedPosition,
            incidents: [
              ...items,
              if (selectedTarget?.incident != null &&
                  !items.any((i) => i.id == selectedTarget!.id))
                selectedTarget!.incident!,
            ],
            supportPlaces: supportPlaces,
            businesses: businesses,
            onBusiness: (p) =>
                setState(() => selectedTarget = MapTarget.business(p)),
            target: selectedTarget?.point,
            selectedId: selectedTarget?.id,
            onSupport: (p) =>
                setState(() => selectedTarget = MapTarget.place(p)),
            onReport: (i) =>
                setState(() => selectedTarget = MapTarget.report(i)),
          ),
        ),
        Positioned(
          top: 0,
          left: 14,
          right: 14,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: MapLocationHeader(
                account: app.account,
                district: districtName,
                province: provinceName,
                hasPosition: userPosition != null,
                onExplore: widget.onOpenDrawer,
                onProfile: widget.onOpenProfile,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 76,
          left: 0,
          right: 0,
          child: MapCategoryFilters(
            selected: type,
            count: items.length,
            onChanged: (value) {
              setState(() => type = value);
              load(background: true);
            },
          ),
        ),
        Positioned(
          right: 14,
          top: MediaQuery.paddingOf(context).top + 132,
          child: _FloatingMapControlButton(
            tooltip: 'Centrar en mi ubicación GPS',
            icon: locating
                ? Icons.hourglass_top_rounded
                : Icons.my_location_rounded,
            active: userPosition != null,
            onTap: locating ? () {} : locate,
          ),
        ),
        if (selectedTarget != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedTarget!.support != null ||
                                    selectedTarget!.businessPoint != null
                                ? selectedTarget!.title
                                : "${crimeTypes.contains(selectedTarget!.incident!.type) ? 'Crimen · ' : ''}${AppScope.of(context).categoryLabel(selectedTarget!.incident!.type)}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: "Cerrar ficha",
                          onPressed: () =>
                              setState(() => selectedTarget = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (selectedTarget!.incident?.mediaId != null ||
                        selectedTarget!.businessPoint?.data["media_id"]
                                is String &&
                            (selectedTarget!.businessPoint!.data["media_id"]
                                    as String)
                                .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            app.api.photoUrl(
                              selectedTarget!.incident?.mediaId ??
                                  selectedTarget!
                                          .businessPoint!
                                          .data["media_id"]
                                      as String,
                            ),
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (selectedTarget!.businessPoint != null)
                      Text(
                        "Promocionado · ${businessKinds[selectedTarget!.businessPoint!.data["kind"]] ?? "Negocio"}",
                      ),
                    Text(
                      selectedTarget!.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Línea de referencia desde tu ubicación",
                      style: TextStyle(fontSize: 12),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final target = selectedTarget!;
                        if (target.incident != null) {
                          open(target.incident!);
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => SafeArea(
                              child: SingleChildScrollView(
                                child: target.businessPoint != null
                                    ? BusinessDetails(
                                        point: target.businessPoint!,
                                      )
                                    : SupportPlaceDetails(
                                        place: target.support!,
                                      ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_full),
                      label: Text(
                        selectedTarget!.incident != null
                            ? "Ver publicación y comentarios"
                            : "Ver información",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (selectedTarget == null)
          Align(
            alignment: Alignment.bottomCenter,
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((sheetExtent - notification.extent).abs() > .005) {
                  setState(() => sheetExtent = notification.extent);
                }
                return false;
              },
              child: MapReportSheet(
                onReport: (category) => triggerCreate(categoryId: category),
                onEmergency: showEmergencyDialer,
                onHelp: () => widget.onOpenHelp?.call(),
                children: [
                  if (app.loading) const LinearProgressIndicator(minHeight: 2),
                  if (app.error != null)
                    MessageCard(
                      'No se pudo actualizar la conexión.',
                      error: true,
                      onRetry: app.initialize,
                    ),
                  if (error != null)
                    MessageCard(error!, error: true, onRetry: () => load()),
                  if (userPosition == null)
                    TextButton.icon(
                      onPressed: locating ? null : locate,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Activar mi ubicación'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryFeedExperience(BuildContext context) {
    final isPlacesDirectory = widget.fixedType == 'place';

    return RefreshIndicator(
      onRefresh: () async {
        await load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
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

          if (widget.fixedType.isEmpty) ...[
            AppChoiceField(
              label: "Tipo de alerta",
              value: crimeTypes.contains(type) ? "crime" : type,
              options: {
                "": "Todas las alertas",
                "crime": "Crimen",
                "fire": "Incendios",
                "emergency": "Emergencias",
                "crash": "Accidentes",
                "pet": "Mascotas",
              },
              onChanged: (v) {
                setState(() => type = v);
                load();
              },
            ),
            if (type == "crime" || crimeTypes.contains(type))
              AppChoiceField(
                label: "Subcategoría de crimen",
                value: type,
                options: {
                  "crime": "Todas",
                  for (final t in crimeTypes)
                    t: AppScope.of(context).categoryLabel(t),
                },
                onChanged: (v) {
                  setState(() => type = v);
                  load();
                },
              ),
            if (AppScope.of(context).account != null)
              FilterChip(
                label: const Text("Mis publicaciones"),
                selected: ownOnly,
                onSelected: (v) {
                  setState(() => ownOnly = v);
                  load();
                },
              ),
            const SizedBox(height: 16),
          ],
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
            SupportPlaceList(
              places: supportPlaces,
              onSelect: widget.onMapTarget == null
                  ? null
                  : (p) => widget.onMapTarget!(MapTarget.place(p)),
            ),
          ],
          if (userPosition == null && !widget.history)
            TextButton.icon(
              onPressed: locating ? null : locate,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Usar mi ubicación para ver lo cercano'),
            ),
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
            ...items.map(
              (i) => ReportTile(
                incident: i,
                onTap: () => widget.onMapTarget != null
                    ? widget.onMapTarget!(MapTarget.report(i))
                    : open(i),
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!busy && error == null && items.isEmpty)
              const MessageCard(
                'No hay publicaciones para estos filtros. Los nuevos reportes se crean desde el mapa.',
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
      color: Theme.of(context).colorScheme.surface,
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
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
