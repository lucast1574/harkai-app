import 'package:flutter/material.dart';
import 'district_directory.dart';
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
  final text = TextEditingController();
  final form = GlobalKey<FormState>();
  Analysis? analysis;
  String? error;
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
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

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
    children: [
      const PageHeading(
        'Ayuda cuando la necesitas',
        'Orientación por reglas y contactos publicados por la administración.',
      ),
      const DistrictDirectory(),
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
    ],
  );
}
