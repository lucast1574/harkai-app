import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
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
  Widget build(BuildContext context) {
    final visual = categoryVisual(draft.type ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: visual.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CategoryGlyph(
                          type: draft.type ?? '',
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.label ?? visual.shortLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ubicación: ${draft.latitude.text}, ${draft.longitude.text}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  draft.description.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const VerificationBadge(false),
                    Chip(
                      avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: Text(draft.photoName ?? 'Sin foto adjunta'),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      avatar: const Icon(Icons.phone_outlined, size: 16),
                      label: Text(
                        draft.shareContact &&
                                draft.contact.text.trim().isNotEmpty
                            ? draft.contact.text.trim()
                            : 'Contacto privado',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.reviewed,
          title: const Text(
            'Revisé el texto y la ubicación. Entiendo que es un reporte comunitario.',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          onChanged: busy ? null : (value) => onReviewed(value ?? false),
        ),
      ],
    );
  }
}
