import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/app_choice_field.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import '../map/map_target.dart';
import '../reports/report_detail.dart';
import '../reports/report_repository.dart';
import 'pet_card.dart';

class PetsScreen extends StatefulWidget {
  final ValueChanged<MapTarget> onMap;
  final Future<void> Function() onCreate;
  const PetsScreen({super.key, required this.onMap, required this.onCreate});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  LatLng? point;
  List<Incident> items = [];
  String? cursor, error;
  String search = '';
  bool initialized = false, locating = false, loading = false;
  int radius = 2000, generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      Future.microtask(locate);
    }
  }

  Future<void> locate() async {
    if (locating) return;
    setState(() {
      locating = true;
      error = null;
    });
    try {
      final p = await currentLocation();
      if (!mounted) return;
      setState(() => point = LatLng(p.latitude, p.longitude));
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> load({bool more = false}) async {
    if (point == null) return locate();
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        items = [];
        cursor = null;
      }
    });
    try {
      final page = await ReportRepository(AppScope.of(context).api).list(
        latitude: point!.latitude,
        longitude: point!.longitude,
        radius: radius,
        type: 'pet',
        archive: true,
        cursor: more ? cursor : null,
      );
      if (mounted && version == generation) {
        setState(() {
          items = {
            for (final item in [
              ...(more ? items : <Incident>[]),
              ...page.items,
            ])
              item.id: item,
          }.values.toList();
          cursor = page.cursor;
        });
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && version == generation) setState(() => loading = false);
    }
  }

  Future<void> open(Incident incident) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetail(
          id: incident.id,
          initialIncident: incident,
          userPosition: point,
          onMap: (i) {
            Navigator.pop(context);
            widget.onMap(MapTarget.report(i));
          },
        ),
      ),
    );
    if (mounted) await load();
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.toLowerCase().trim();
    final results =
        items
            .where(
              (i) =>
                  i.type == 'pet' &&
                  i.status != 'hidden' &&
                  const Distance()(point!, LatLng(i.latitude, i.longitude)) <=
                      radius &&
                  '${i.description} ${i.district ?? ''} ${i.city ?? ''}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList()
          ..sort(
            (a, b) => const Distance()(point!, LatLng(a.latitude, a.longitude))
                .compareTo(
                  const Distance()(point!, LatLng(b.latitude, b.longitude)),
                ),
          );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ayuda a que vuelvan a casa.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await widget.onCreate();
                      if (mounted) await load();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Publicar'),
                  ),
                ],
              ),
              AppChoiceField(
                label: 'Cerca de ti · Incluye distritos vecinos',
                value: '$radius',
                options: const {
                  '2000': '2 km a la redonda',
                  '5000': '5 km a la redonda',
                  '10000': '10 km a la redonda',
                },
                onChanged: (v) {
                  setState(() => radius = int.parse(v));
                  load();
                },
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por rasgos o zona',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: results.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loading || locating) const LinearProgressIndicator(),
                      if (error != null)
                        MessageCard(
                          error!,
                          error: true,
                          onRetry: point == null ? locate : load,
                        ),
                      if (!loading && !locating && error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${results.length} ${results.length == 1 ? 'aviso' : 'avisos'}${cursor != null ? ' cargados' : ' en esta vista'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      if (!loading &&
                          !locating &&
                          error == null &&
                          results.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No hay avisos en esta búsqueda. Amplía el radio o prueba otros rasgos.',
                          ),
                        ),
                    ],
                  );
                }
                if (index == results.length + 1) {
                  return cursor == null
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: loading ? null : () => load(more: true),
                          child: const Text('Ver más avisos'),
                        );
                }
                final incident = results[index - 1];
                return PetCard(
                  key: ValueKey(incident.id),
                  incident: incident,
                  origin: point!,
                  onOpen: () => open(incident),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
