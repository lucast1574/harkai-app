import 'package:flutter/material.dart';

class ReportDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const ReportDescriptionField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Qué ocurrió?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: 4,
          maxLines: 6,
          maxLength: 2000,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Describe lo que viste y hace cuánto pasó.',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          validator: (value) => (value?.trim().runes.length ?? 0) < 5
              ? 'Describe brevemente lo ocurrido.'
              : null,
        ),
      ],
    );
  }
}
