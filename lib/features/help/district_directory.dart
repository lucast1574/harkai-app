import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
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
              'Ayuda por distrito',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Líneas nacionales y contactos locales publicados por las entidades.',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              borderRadius: BorderRadius.circular(16),
              initialValue: city,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              items: const [
                DropdownMenuItem(value: 'lima', child: Text('Lima')),
                DropdownMenuItem(value: 'trujillo', child: Text('Trujillo')),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        city = value;
                        district = value == 'lima' ? 'Lima' : 'Trujillo';
                      });
                      widget.onCityChange?.call(value);
                      load();
                    },
            ),
            const SizedBox(height: 14),
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
            if (busy) const LinearProgressIndicator(),
            if (error != null) ...[
              MessageCard(error!, error: true),
              TextButton(onPressed: load, child: const Text('Reintentar')),
            ],
            ...contacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c['label'] as String),
                      subtitle: Text(
                        '${c['scope'] == 'distrital' ? district : 'Línea nacional'} · ${c['phone']}',
                      ),
                      trailing: const Icon(Icons.phone_outlined),
                      onTap: () => launchUrl(
                        Uri(scheme: 'tel', path: c['phone'] as String),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(c['source_url'] as String),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Fuente institucional'),
                    ),
                  ],
                ),
              ),
            ),
            if (contacts.isNotEmpty &&
                !contacts.any((c) => c['scope'] == 'distrital'))
              const MessageCard(
                'Las líneas nacionales están disponibles. El contacto municipal de este distrito está pendiente de contraste.',
              ),
            if (contacts.isNotEmpty)
              Text(
                'Fuentes consultadas: ${contacts.first['reviewed_at']}. Harkai no llama ni avisa a emergencias automáticamente.',
              ),
          ],
        ),
      ),
    );
  }
}
