import 'package:flutter/material.dart';

String? reportContactValidator(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Añade el teléfono que quieres mostrar.';
  if (text.length > 40 || !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text)) {
    return 'Usa solo números, espacios, paréntesis o guiones.';
  }
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 9 || digits.length > 15) {
    return 'Escribe entre 9 y 15 dígitos, incluido el código de país si lo usas.';
  }
  return null;
}

String normalizedReportContact(String value) =>
    value.trim().replaceAll(RegExp(r'[ ()-]'), '');

class ReportContactField extends StatelessWidget {
  final TextEditingController controller;
  final bool share, enabled;
  final ValueChanged<bool> onShare;

  const ReportContactField({
    super.key,
    required this.controller,
    required this.share,
    required this.enabled,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Mostrar mi teléfono', style: theme.textTheme.titleSmall),
          subtitle: const Text(
            'Opcional. Al activarlo, cualquier persona que vea el reporte podrá llamarte.',
          ),
          value: share,
          onChanged: enabled ? onShare : null,
        ),
        if (share) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto',
              hintText: 'Ej. 987 654 321 o +51 987 654 321',
              helperText: 'Este número será público en tu reporte.',
              helperMaxLines: 2,
              errorMaxLines: 3,
            ),
            validator: reportContactValidator,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ],
      ],
    );
  }
}
