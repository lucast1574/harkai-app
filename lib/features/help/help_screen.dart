import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../reports/report_repository.dart';
import 'district_directory.dart';

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
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
    children: [
      // Harkbot Hero Banner
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/bot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.support_agent_rounded,
                    color: navy,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asistente y Directorio Harkai',
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Líneas de emergencia rápida, contactos por distrito y orientación inmediata.',
                    style: TextStyle(color: Color(0xffcbd5e1), fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Quick Emergency Dial Grid
      Row(
        children: [
          Expanded(
            child: _EmergencyCallTile(
              label: 'Policía',
              number: '105',
              color: const Color(0xff1e3a8a),
              icon: Icons.local_police_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _EmergencyCallTile(
              label: 'Bomberos',
              number: '116',
              color: const Color(0xffea580c),
              icon: Icons.local_fire_department_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _EmergencyCallTile(
              label: 'SAMU Salud',
              number: '106',
              color: const Color(0xffb91c1c),
              icon: Icons.medical_services_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _EmergencyCallTile(
              label: 'Extorsiones',
              number: '1818',
              color: const Color(0xff4f46e5),
              icon: Icons.gpp_maybe_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Interactive Orientation Card
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: navy),
                    const SizedBox(width: 8),
                    Text(
                      'Orientación rápida por situación',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Describe qué está ocurriendo para recibir pasos preventivos inmediatos.',
                  style: TextStyle(fontSize: 13, color: Color(0xff64748b)),
                ),
                const SizedBox(height: 14),
                AppField(
                  label: '¿Qué está ocurriendo?',
                  controller: text,
                  lines: 3,
                  maxLength: 2000,
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? 'Escribe al menos cinco caracteres.'
                      : null,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy || AppScope.of(context).account == null
                        ? null
                        : ask,
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(
                      busy
                          ? 'Consultando…'
                          : 'Ver recomendaciones de seguridad',
                    ),
                  ),
                ),
                if (AppScope.of(context).account == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Ingresa con tu cuenta para consultar orientación por texto.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (error != null) MessageCard(error!, error: true),
                if (analysis != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis!.reason,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...analysis!.advice.map(
                          (a) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• $a'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      // District Directory
      const DistrictDirectory(),
    ],
  );
}

class _EmergencyCallTile extends StatelessWidget {
  final String label, number;
  final Color color;
  final IconData icon;
  const _EmergencyCallTile({
    required this.label,
    required this.number,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => launchUrl(Uri(scheme: 'tel', path: number)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    ),
  );
}
