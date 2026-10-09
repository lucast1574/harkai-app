import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import 'report_draft.dart';
import 'voice_input.dart';
import '../../core/app_scope.dart';

class ReportDescriptionStep extends StatelessWidget {
  final ReportDraft draft;
  final bool busy;
  final List<Category> categories;
  final Analysis? analysis;
  final VoidCallback analyze;
  final ValueChanged<String?> onType;
  const ReportDescriptionStep({
    super.key,
    required this.draft,
    required this.busy,
    required this.categories,
    required this.analysis,
    required this.analyze,
    required this.onType,
  });
  @override
  Widget build(BuildContext context) {
    final category = categories.where((c) => c.id == draft.type).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppScope.of(context).capabilities['audio'] == true)
          VoiceInput(
            disabled: busy,
            onTranscript: (text, result) {
              draft.description.text = text;
              if (draft.type == null) onType(result.suggestedType);
            },
          ),
        AppField(
          label: 'Describe lo que observaste',
          controller: draft.description,
          lines: 5,
          maxLength: 2000,
          validator: (v) => (v?.trim().length ?? 0) < 5
              ? 'Describe lo ocurrido en al menos cinco caracteres.'
              : null,
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : analyze,
          icon: const Icon(Icons.manage_search),
          label: const Text('Sugerir categoría por texto'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(draft.type),
          initialValue: draft.type,
          decoration: const InputDecoration(labelText: 'Categoría del reporte'),
          validator: (v) => v == null ? 'Elige una categoría.' : null,
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label)))
              .toList(),
          onChanged: busy ? null : onType,
        ),
        if (analysis != null)
          MessageCard(
            '${analysis!.reason} Confirma o cambia la categoría sugerida.',
          ),
        const SizedBox(height: 14),
        ...?category?.advice.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('• $a'),
          ),
        ),
      ],
    );
  }
}
