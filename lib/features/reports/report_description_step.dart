import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
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
        Text(
          '1. ¿Qué tipo de situación quieres reportar?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        FormField<String>(
          key: ValueKey(draft.type),
          initialValue: draft.type,
          validator: (v) => (draft.type == null || draft.type!.isEmpty)
              ? 'Elige una categoría.'
              : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  final visual = categoryVisual(c.id);
                  final selected = draft.type == c.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: busy
                        ? null
                        : () {
                            onType(c.id);
                            state.didChange(c.id);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? visual.color
                            : visual.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? visual.color
                              : visual.color.withValues(alpha: 0.35),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CategoryGlyph(
                            type: c.id,
                            size: 16,
                            color: selected ? Colors.white : visual.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : visual.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '2. Describe brevemente lo que observaste',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (AppScope.of(context).capabilities['audio'] == true) ...[
          VoiceInput(
            disabled: busy,
            onTranscript: (text, result) {
              draft.description.text = text;
              if (draft.type == null) onType(result.suggestedType);
            },
          ),
          const SizedBox(height: 10),
        ],
        AppField(
          label: '¿Qué pasó, dónde y hace cuánto?',
          controller: draft.description,
          lines: 4,
          maxLength: 2000,
          validator: (v) => (v?.trim().length ?? 0) < 5
              ? 'Describe lo ocurrido en al menos cinco caracteres.'
              : null,
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : analyze,
          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
          label: const Text('Sugerir categoría según mi texto'),
        ),
        if (analysis != null) ...[
          const SizedBox(height: 12),
          MessageCard(
            '${analysis!.reason} Confirma o cambia la categoría sugerida.',
          ),
        ],
        if (category != null && category.advice.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryVisual(category.id).color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: categoryVisual(
                  category.id,
                ).color.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: categoryVisual(category.id).color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recomendaciones de seguridad',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: categoryVisual(category.id).color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...category.advice.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $a', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
