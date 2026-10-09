import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../map/community_map.dart';
import '../location/location_service.dart';
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
  LatLng center = const LatLng(-12.0464, -77.0428);
  int radius = 5000;
  String type = '';
  List<Incident> items = [];
  String? cursor, error;
  bool busy = false, initialized = false;
  int generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      type = widget.fixedType;
      Future.microtask(() => load());
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
    return items.length;
  }

  Future<bool> locate() async {
    try {
      final p = await currentLocation();
      if (!mounted) return false;
      setState(() => center = LatLng(p.latitude, p.longitude));
      await load();
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    }
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
          if (error != null)
            MessageCard(error!, error: true, onRetry: () => load()),
          if (widget.showMap)
            SizedBox(
              height: 340,
              child: CommunityMap(
                center: center,
                incidents: items,
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
