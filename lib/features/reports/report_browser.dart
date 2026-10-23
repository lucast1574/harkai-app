import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../../shared/account_avatar.dart';
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
  List<Incident> items = [];
  List<SupportPlace> supportPlaces = [];
  String? supportError;
  String? cursor, error;
  bool busy = false, initialized = false;
  int generation = 0;
  int focusRequest = 0;
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
        if (!widget.history) await location!.start();
      });
    }
  }

  Future<int> load({bool more = false, bool background = false}) async {
    if (!mounted || (!widget.history && userPosition == null)) return 0;
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
      }
    });
    if (p.accuracy <= 250) {
      unawaited(Future.wait([load(background: true), loadCoverage(p)]));
    }
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
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: CommunityMap(
            fullScreen: true,
            focusRequest: focusRequest,
            bottomObstruction: sheetExtent * MediaQuery.sizeOf(context).height,
            topObstruction: MediaQuery.paddingOf(context).top + 80,
            userPositionFresh:
                positionTime != null &&
                DateTime.now().difference(positionTime!) <
                    const Duration(minutes: 2),
            center: center,
            userPosition: userPosition,
            incidents: items,
            supportPlaces: supportPlaces,
            onReport: open,
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
              child: Material(
                color: colors.surface,
                elevation: 4,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Explorar Harkai',
                        onPressed: widget.onOpenDrawer,
                        icon: Image.asset(
                          'assets/icon/icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'harkai',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mi cuenta',
                        onPressed: widget.onOpenProfile,
                        icon: AccountAvatar(account: app.account),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: MediaQuery.paddingOf(context).top + 84,
          child: _FloatingMapControlButton(
            tooltip: 'Centrar en mi ubicación GPS',
            icon: locating
                ? Icons.hourglass_top_rounded
                : Icons.my_location_rounded,
            active: userPosition != null,
            onTap: locating ? () {} : locate,
          ),
        ),
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
    final isPetsSection = widget.fixedType == 'pet';

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
            ...items.map((i) => ReportTile(incident: i, onTap: () => open(i))),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!busy && error == null && items.isEmpty)
              const MessageCard(
                'Aún no hay reportes cercanos. Puedes publicar lo que está pasando.',
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
