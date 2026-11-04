import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_scope.dart';
import '../../shared/app_choice_field.dart';
import '../../shared/directory_photo.dart';
import '../../shared/widgets.dart';
import '../location/location_service.dart';
import '../map/map_target.dart';
import 'support_place.dart';
import 'support_directory_results.dart';
import 'support_proximity.dart';

class SupportDirectory extends StatefulWidget {
  final ValueChanged<MapTarget> onMap;
  const SupportDirectory({super.key, required this.onMap});
  @override
  State<SupportDirectory> createState() => _SupportDirectoryState();
}

class _SupportDirectoryState extends State<SupportDirectory> {
  List<SupportPlace> places = [];
  LatLng? point;
  int radius = 2000, generation = 0;
  String kind = '', search = '';
  String? error;
  bool initialized = false, loading = false, locating = false;

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

  Future<void> load() async {
    if (point == null) return locate();
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      places = [];
    });
    try {
      final data = await AppScope.of(context).api.request(
        'GET',
        'support/places?lat=${point!.latitude}&lng=${point!.longitude}&radius_meters=$radius',
        authenticated: false,
      );
      if (mounted && version == generation) {
        setState(
          () => places = (data['items'] as List)
              .map((p) => SupportPlace.fromJson(p as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && version == generation) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = point == null
        ? <NearbySupport>[]
        : supportDirectoryResults(
            places,
            point!,
            radius: radius.toDouble(),
            kind: kind,
            search: search,
          );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              AppChoiceField(
                label: 'Desde tu ubicación · Incluye distritos vecinos',
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
                  hintText: 'Buscar un centro o una zona',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in const {
                      '': 'Todos',
                      'health': 'Salud',
                      'police': 'Policía',
                      'fire_station': 'Bomberos',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: kind == entry.key,
                          onSelected: (_) => setState(() => kind = entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + 1,
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
                            '${items.length} centros · Del más cercano al más lejano',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (items.isEmpty &&
                          !loading &&
                          !locating &&
                          error == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No hay centros en esta búsqueda. Amplía el radio o prueba otro filtro.',
                          ),
                        ),
                    ],
                  );
                }
                final item = items[index - 1];
                final SupportPlace place = item.place;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onMap(MapTarget.place(place)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          DirectoryPhoto(
                            url: place.photoUrls.firstOrNull,
                            fallback: place.kindIcon,
                            label: place.name,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${place.kindLabel} · ${place.district}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'A ${nearbyDistanceLabel(item.meters)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
