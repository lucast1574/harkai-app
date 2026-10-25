import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class EmergencySheet extends StatefulWidget {
  final double? latitude, longitude;
  const EmergencySheet({super.key, this.latitude, this.longitude});
  @override
  State<EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends State<EmergencySheet> {
  bool initialized = false, busy = true;
  String? error, lastType;
  String area = 'Líneas nacionales';
  List<Map<String, dynamic>> contacts = [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      load();
    }
  }

  Future<bool> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    final app = AppScope.of(context);
    final owner = app.account?.id;
    var lat = widget.latitude, lng = widget.longitude;
    String? district;
    var city = 'lima';
    try {
      if (owner != null) {
        final reports = await app.api.request('GET', 'me/incidents?limit=1');
        final items = reports['items'] as List;
        if (items.isNotEmpty) {
          final report = items.first as Map<String, dynamic>;
          lastType = report['type'] as String;
          lat ??= (report['latitude'] as num).toDouble();
          lng ??= (report['longitude'] as num).toDouble();
        }
      }
      if (lat != null && lng != null) {
        try {
          final geo = await app.api.request(
            'GET',
            'geo/district?lat=$lat&lng=$lng',
          );
          final place = geo['district'] as Map<String, dynamic>;
          final province = (place['id'] as String).substring(0, 4);
          district = place['name'] as String;
          city = ['1501', '0701'].contains(province)
              ? 'lima'
              : province == '1301'
              ? 'trujillo'
              : province;
        } catch (_) {
          /* National contacts remain available outside coverage. */
        }
      }
      final result = await app.api.request(
        'GET',
        'support/directory?city=$city',
      );
      final districts = (result['items'] as List).cast<Map<String, dynamic>>();
      final local = districts
          .where((item) => item['district'] == district)
          .firstOrNull;
      final source = local ?? districts.firstOrNull;
      final available = (source?['contacts'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((item) => local != null || item['scope'] == 'nacional')
          .toList();
      available.sort(
        (a, b) => emergencyPriority(
          a['label'] as String,
          lastType,
        ).compareTo(emergencyPriority(b['label'] as String, lastType)),
      );
      if (!mounted || app.account?.id != owner) return false;
      setState(() {
        contacts = available;
        area = district ?? 'Líneas nacionales';
      });
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo consultar el directorio. Vuelve a intentarlo.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Emergencias',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              lastType == null
                  ? 'Directorio de ayuda · $area'
                  : 'Según tu último reporte: ${categoryVisual(lastType!).shortLabel} · $area',
            ),
            const SizedBox(height: 16),
            if (busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (error != null) MessageCard(error!, error: true, onRetry: load),
            if (!busy)
              for (final item in contacts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_in_talk_outlined),
                  title: Text('${item['label']} · ${item['phone']}'),
                  subtitle: Text(
                    'Fuente contrastada · revisión ${item['reviewed_at']}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Ver fuente',
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    onPressed: () =>
                        launchUrl(Uri.parse(item['source_url'] as String)),
                  ),
                  onTap: () => launchUrl(
                    Uri(scheme: 'tel', path: item['phone'] as String),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}

int emergencyPriority(String label, String? type) {
  final name = label.toLowerCase();
  if (type == 'fire' && name.contains('bombero')) return 0;
  if (type == 'emergency' && name.contains('samu')) return 0;
  if (type == 'extortion' && name.contains('extorsi')) return 0;
  if (type == 'violence' && name.contains('100')) return 0;
  if (name.contains('polic')) return 1;
  return 2;
}
