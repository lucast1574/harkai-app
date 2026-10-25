import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const safetyEmail = 'lucasraulsantillanarevalo@gmail.com';

class SafetyReportButton extends StatelessWidget {
  final String? incidentId;
  final Future<bool> Function(Uri)? open;
  const SafetyReportButton({super.key, this.incidentId, this.open});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.flag_outlined, size: 18),
    label: const Text('Denunciar contenido'),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SafetyReportSheet(incidentId: incidentId, open: open),
    ),
  );
}

class _SafetyReportSheet extends StatefulWidget {
  final String? incidentId;
  final Future<bool> Function(Uri)? open;
  const _SafetyReportSheet({this.incidentId, this.open});

  @override
  State<_SafetyReportSheet> createState() => _SafetyReportSheetState();
}

class _SafetyReportSheetState extends State<_SafetyReportSheet> {
  bool busy = false, unavailable = false;

  Future<void> compose(String reason) async {
    if (busy) return;
    setState(() => busy = true);
    final link = widget.incidentId == null
        ? 'Indica el enlace de la publicación o conversación.'
        : Uri(
            scheme: 'https',
            host: 'panel.harkai.lat',
            pathSegments: ['incidents', widget.incidentId!],
          ).toString();
    final uri = Uri(
      scheme: 'mailto',
      path: safetyEmail,
      query:
          'subject=${Uri.encodeComponent('Harkai · $reason')}'
          '&body=${Uri.encodeComponent('$link\n\nMotivo de la denuncia:\n')}',
    );
    try {
      final opened =
          await (widget.open?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (mounted) setState(() => unavailable = !opened);
    } catch (_) {
      if (mounted) setState(() => unavailable = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cuidemos la comunidad',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Se abrirá tu correo para que revises y envíes la denuncia '
          'al equipo de Harkai. Incluye el enlace y explica el problema.',
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Seguridad de menores'),
          subtitle: const Text('Explotación, abuso o contacto inapropiado'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: busy ? null : () => compose('Seguridad de menores'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Otro contenido indebido'),
          subtitle: const Text(
            'Acoso, datos personales o información peligrosa',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: busy ? null : () => compose('Contenido indebido'),
        ),
        const SizedBox(height: 10),
        const Text(
          'No descargues ni adjuntes material de abuso sexual infantil. '
          'Este canal no sustituye a los servicios de emergencia.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
        if (unavailable)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              'No se pudo abrir una app de correo. Copia la dirección '
              'y envía tu denuncia desde el servicio que uses. '
              'Todavía no se ha enviado.',
            ),
          ),
        const SizedBox(height: 12),
        const SelectableText(safetyEmail),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: safetyEmail));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Correo copiado')));
            }
          },
          icon: const Icon(Icons.copy_outlined, size: 16),
          label: const Text('Copiar correo'),
        ),
      ],
    ),
  );
}
