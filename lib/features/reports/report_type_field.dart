import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/app_choice_field.dart';
import 'report_classifier.dart';

class ReportTypeField extends StatelessWidget {
  final ReportClassifier classifier;
  final List<Category> categories;
  final bool enabled;
  const ReportTypeField({
    super.key,
    required this.classifier,
    required this.categories,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final type = classifier.type;
    final label = categories.where((c) => c.id == type).firstOrNull?.label;
    final message = classifier.analyzing
        ? 'Identificando lo que describes…'
        : classifier.error ??
              (classifier.manualType != null
                  ? 'Elegiste este tipo de alerta.'
                  : label != null
                  ? 'Se identificó por tu descripción. Puedes cambiarlo.'
                  : classifier.analysis != null
                  ? 'Hay dudas sobre el tipo. Elige el que mejor describa el hecho.'
                  : 'El tipo se ajustará a tu descripción.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChoiceField(
          label: 'Tipo de alerta',
          value: classifier.manualType ?? '',
          options: {
            '': classifier.manualType == null && label != null
                ? '$label · automático'
                : 'Identificar automáticamente',
            for (final category in categories)
              if (category.id != 'place') category.id: category.label,
          },
          onChanged: enabled ? classifier.selectType : null,
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
