import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import 'report_draft.dart';

class ReportReviewStep extends StatelessWidget {
  final ReportDraft draft;
  final Category? category;
  final bool busy;
  final ValueChanged<bool> onReviewed;
  const ReportReviewStep({
    super.key,
    required this.draft,
    required this.category,
    required this.busy,
    required this.onReviewed,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        category?.label ?? '',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 18),
      Text(draft.description.text),
      const SizedBox(height: 18),
      Text('Ubicación: ${draft.latitude.text}, ${draft.longitude.text}'),
      Text('Evidencia: ${draft.photoName ?? 'Sin foto'}'),
      Text(
        'Contacto público: ${draft.shareContact ? draft.contact.text : 'No se compartirá'}',
      ),
      const SizedBox(height: 18),
      const VerificationBadge(false),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: draft.reviewed,
        title: const Text(
          'Revisé el texto y la ubicación. Entiendo que es un reporte comunitario.',
        ),
        onChanged: busy ? null : (value) => onReviewed(value ?? false),
      ),
    ],
  );
}
