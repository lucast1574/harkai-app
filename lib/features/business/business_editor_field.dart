import 'package:flutter/material.dart';

class BusinessEditorField extends StatelessWidget {
  final String name, label;
  final TextEditingController controller;
  final bool enabled;
  const BusinessEditorField({
    super.key,
    required this.name,
    required this.label,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            key: ValueKey('business-$name'),
            controller: controller,
            enabled: enabled,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            minLines: name == 'description' ? 3 : 1,
            maxLines: name == 'description'
                ? 5
                : name == 'offer'
                ? 3
                : 1,
            maxLength: switch (name) {
              'description' => 2000,
              'phone' => 30,
              'subtype' => 80,
              'offer' => 160,
              'discount_code' => 32,
              'name' => 100,
              _ => 300,
            },
            keyboardType: switch (name) {
              'phone' => TextInputType.phone,
              'website' => TextInputType.url,
              'description' || 'offer' => TextInputType.multiline,
              _ => TextInputType.text,
            },
            textCapitalization: name == 'discount_code'
                ? TextCapitalization.characters
                : name == 'website' || name == 'phone'
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            textInputAction: name == 'description' || name == 'offer'
                ? TextInputAction.newline
                : TextInputAction.next,
            decoration: InputDecoration(
              counterText: '',
              hintText: switch (name) {
                'website' => 'https://',
                'description' => 'Describe tus productos o servicios',
                'offer' => 'Por ejemplo: 15 % en tu primera visita',
                'discount_code' => 'VECINOS15',
                _ => null,
              },
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if ((name == 'name' && text.length < 2) ||
                  (name == 'description' && text.length < 5)) {
                return 'Completa este campo.';
              }
              if (name == 'website' && text.isNotEmpty) {
                final url = Uri.tryParse(text);
                if (url == null || url.scheme != 'https' || url.host.isEmpty) {
                  return 'Usa una dirección https:// válida.';
                }
              }
              if (name == 'discount_code' &&
                  text.isNotEmpty &&
                  !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(text)) {
                return 'Usa letras, números o guiones.';
              }
              return null;
            },
          ),
        ),
      ],
    ),
  );
}
