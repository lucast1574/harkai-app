import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class DistrictDirectory extends StatefulWidget {
  final ValueChanged<String>? onCityChange;
  const DistrictDirectory({super.key, this.onCityChange});
  @override
  State<DistrictDirectory> createState() => _DistrictDirectoryState();
}

class _DistrictDirectoryState extends State<DistrictDirectory> {
  String city = 'lima', district = 'Lima';
  List<Map<String, dynamic>> items = [];
  bool initialized = false, busy = false;
  String? error;
  int generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      Future.microtask(load);
    }
  }

  Future<int> load() async {
    final version = ++generation;
    setState(() {
      busy = true;
      error = null;
      items = [];
    });
    try {
      final result = await AppScope.of(
        context,
      ).api.request('GET', 'support/directory?city=$city');
      if (mounted && version == generation) {
        setState(
          () => items = (result['items'] as List).cast<Map<String, dynamic>>(),
        );
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

  @override
  Widget build(BuildContext context) {
    final matches = items.where((d) => d['district'] == district);
    final contacts = matches.isEmpty
        ? <Map<String, dynamic>>[]
        : (matches.first['contacts'] as List).cast<Map<String, dynamic>>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Directorio telefónico por distrito',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Serenazgo y centrales municipales verificadas.',
              style: TextStyle(fontSize: 13, color: Color(0xff64748b)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text('Lima y Callao', textAlign: TextAlign.center),
                    ),
                    selected: city == 'lima',
                    onSelected: busy
                        ? null
                        : (_) {
                            setState(() {
                              city = 'lima';
                              district = 'Lima';
                            });
                            widget.onCityChange?.call('lima');
                            load();
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text('Trujillo', textAlign: TextAlign.center),
                    ),
                    selected: city == 'trujillo',
                    onSelected: busy
                        ? null
                        : (_) {
                            setState(() {
                              city = 'trujillo';
                              district = 'Trujillo';
                            });
                            widget.onCityChange?.call('trujillo');
                            load();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('$city:${items.length}'),
              initialValue: matches.isEmpty ? null : district,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Distrito'),
              items: items
                  .map(
                    (d) => DropdownMenuItem(
                      value: d['district'] as String,
                      child: Text(d['district'] as String),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => district = value);
                    },
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (error != null) ...[
              const SizedBox(height: 12),
              MessageCard(error!, error: true, onRetry: load),
            ],
            ...contacts.map(
              (c) => Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c['scope'] == 'distrital'
                        ? green.withValues(alpha: 0.2)
                        : navy.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      color: c['scope'] == 'distrital'
                          ? const Color(0xff166534)
                          : navy,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    c['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${c['scope'] == 'distrital' ? district : 'Línea nacional'} · ${c['phone']}',
                  ),
                  trailing: FilledButton.tonalIcon(
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: c['phone'] as String),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Llamar'),
                  ),
                ),
              ),
            ),
            if (contacts.isNotEmpty &&
                !contacts.any((c) => c['scope'] == 'distrital')) ...[
              const SizedBox(height: 12),
              const MessageCard(
                'Las líneas nacionales están disponibles. El contacto municipal de este distrito está pendiente de contraste.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
