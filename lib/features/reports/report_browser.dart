import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../location/foreground_location.dart';
import '../help/support_proximity.dart';
import '../help/support_proximity_notice.dart';
import '../help/nearby_support_card.dart';
import '../help/coverage_notice.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../map/community_map.dart';
import '../help/district_directory.dart';
import '../help/support_place.dart';
import '../help/support_place_list.dart';
import 'report_repository.dart';
import 'report_tile.dart';
import 'report_detail.dart';

class ReportBrowser extends StatefulWidget {
  final String title, fixedType;
  final bool history, alerts, showMap;
  const ReportBrowser({
    super.key,
    this.title = 'El pulso de tu zona',
    this.fixedType = '',
    this.history = false,
    this.alerts = false,
    this.showMap = true,
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
  int radius = 5000;
  String type = '';
  List<Incident> items = [];
  List<SupportPlace> supportPlaces = [];
  String? supportError;
  bool showSupport = true;
  String? cursor, error;
  bool busy = false, initialized = false;
  int generation = 0;
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
      Future.microtask(() async {
        unawaited(load());
        if (supportEnabled) await location!.start();
      });
    }
  }

  Future<int> load({bool more = false}) async {
    final version = ++generation;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        items = [];
        cursor = null;
      }
    });
    final supportLoad = supportEnabled && !more
        ? loadSupport(version)
        : Future.value(0);
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

  Future<bool> locate() async => location!.start(requestPermission: true);

  Future<bool> acceptPosition(Position p) async {
    if (!mounted) return false;
    setState(() {
      covered = null;
      coverageError = null;
      userPosition = LatLng(p.latitude, p.longitude);
      userAccuracy = p.accuracy;
      positionTime = p.timestamp;
      if (p.accuracy <= 150) center = userPosition!;
    });
    if (p.accuracy <= 150) await Future.wait([load(), loadCoverage(p)]);
    return true;
  }

  Future<bool> loadCoverage(Position position) async {
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'support/coverage?lat=${position.latitude}&lng=${position.longitude}',
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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await load();
        return;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 100),
        children: [
          PageHeading(
            widget.title,
            'Reportes comunitarios. La confirmación no sustituye una verificación oficial.',
          ),
          if (widget.fixedType == 'place')
            DistrictDirectory(
              onCityChange: (city) {
                setState(() {
                  center = city == 'trujillo'
                      ? const LatLng(-8.1116, -79.0287)
                      : const LatLng(-12.0464, -77.0428);
                  radius = 50000;
                });
                load();
              },
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : locate,
                icon: const Icon(Icons.my_location, size: 17),
                label: const Text('Mi ubicación'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => load(),
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.fixedType.isEmpty)
            DropdownButtonFormField<String>(
              borderRadius: BorderRadius.circular(16),
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todas')),
                ...app.categories.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.label)),
                ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() => type = value ?? '');
                      load();
                    },
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            borderRadius: BorderRadius.circular(16),
            initialValue: radius,
            decoration: const InputDecoration(labelText: 'Radio de consulta'),
            items: [500, 1000, 5000, 10000, 50000]
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(r < 1000 ? '$r m' : '${r ~/ 1000} km'),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (r) {
                    setState(() => radius = r!);
                    load();
                  },
          ),
          const SizedBox(height: 18),
          if (supportPlaces.isNotEmpty)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar centros de salud y ayuda'),
              subtitle: const Text('Cruz blanca en rojo · lugares permanentes'),
              value: showSupport,
              onChanged: (v) => setState(() => showSupport = v ?? true),
            ),
          if (supportEnabled)
            CoverageNotice(covered: covered, error: coverageError),
          if (supportEnabled) NearbySupportCard(nearby: nearby),
          if (supportError != null) MessageCard(supportError!, error: true),
          if (widget.fixedType == 'place')
            SupportPlaceList(places: supportPlaces),
          if (error != null)
            MessageCard(error!, error: true, onRetry: () => load()),
          if (widget.showMap)
            SizedBox(
              height: 340,
              child: CommunityMap(
                center: center,
                userPosition: userPosition,
                incidents: items,
                supportPlaces: showSupport ? supportPlaces : const [],
                onReport: open,
                onPoint: (point) {
                  setState(() => center = point);
                  load();
                },
              ),
            ),
          const SizedBox(height: 18),
          Text(
            '${items.length} reportes cargados${cursor != null ? ' · hay más resultados' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ...items.map((i) => ReportTile(incident: i, onTap: () => open(i))),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!busy && error == null && items.isEmpty)
            const MessageCard(
              'Aún no hay reportes en esta consulta. Puedes cambiar la categoría o la zona. La ausencia de reportes no garantiza que no existan riesgos.',
            ),
          if (cursor != null)
            OutlinedButton(
              onPressed: busy ? null : () => load(more: true),
              child: const Text('Cargar más reportes'),
            ),
        ],
      ),
    );
  }
}
