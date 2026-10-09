import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import '../reports/report_repository.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final text = TextEditingController(),
      city = TextEditingController(text: 'lima');
  final form = GlobalKey<FormState>();
  Analysis? analysis;
  Map<String, dynamic>? numbers;
  String? error, directoryMessage;
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    city.dispose();
    super.dispose();
  }

  Future<bool> ask() async {
    if (!form.currentState!.validate()) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ReportRepository(
        AppScope.of(context).api,
      ).analyze(text.text);
      if (mounted) setState(() => analysis = result);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<int> contacts() async {
    try {
      final result = await AppScope.of(context).api.request(
        'GET',
        'emergency-contacts?${Uri(queryParameters: {'country': 'PE', 'city': city.text.trim()}).query}',
      );
      if (mounted) {
        setState(() {
          numbers = result['numbers'] as Map<String, dynamic>;
          directoryMessage = null;
        });
      }
      return numbers?.length ?? 0;
    } catch (e) {
      if (mounted) {
        setState(() {
          numbers = null;
          directoryMessage =
              'No hay un directorio disponible para esta ciudad. Consulta el canal oficial de tu zona.';
        });
      }
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
    children: [
      const PageHeading(
        'Ayuda cuando la necesitas',
        'Orientación por reglas y contactos publicados por la administración.',
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppField(
                  label: '¿Qué está ocurriendo?',
                  controller: text,
                  lines: 4,
                  maxLength: 2000,
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? 'Escribe al menos cinco caracteres.'
                      : null,
                ),
                FilledButton(
                  onPressed: busy || AppScope.of(context).account == null
                      ? null
                      : ask,
                  child: Text(busy ? 'Consultando…' : 'Ver recomendaciones'),
                ),
                if (AppScope.of(context).account == null)
                  const Text('Ingresa para consultar orientación por texto.'),
                if (error != null) MessageCard(error!, error: true),
                if (analysis != null) ...[
                  const SizedBox(height: 18),
                  Text(analysis!.reason),
                  ...analysis!.advice.map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('• $a'),
                    ),
                  ),
                  const MessageCard(
                    'La orientación no confirma un hecho ni contacta a emergencias.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contactos de ayuda',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppField(label: 'Ciudad', controller: city),
              OutlinedButton(
                onPressed: contacts,
                child: const Text('Consultar contactos'),
              ),
              if (directoryMessage != null) MessageCard(directoryMessage!),
              ...?numbers?.entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    {
                          'police': 'Policía',
                          'firefighters': 'Bomberos',
                          'medical': 'Emergencias médicas',
                          'municipal': 'Municipalidad',
                        }[e.key] ??
                        e.key,
                  ),
                  subtitle: Text(e.value as String),
                  trailing: const Icon(Icons.phone_outlined),
                  onTap: () => launchUrl(
                    Uri(
                      scheme: 'tel',
                      path: (e.value as String).replaceAll(
                        RegExp(r'[^+0-9]'),
                        '',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
