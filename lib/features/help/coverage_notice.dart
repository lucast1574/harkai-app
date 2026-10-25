import 'package:flutter/material.dart';

class CoverageNotice extends StatelessWidget {
  final bool? covered;
  final String? error;
  const CoverageNotice({super.key, this.covered, this.error});
  @override
  Widget build(BuildContext context) {
    if (covered != false && error == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.map_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    covered == false
                        ? 'Ubicación fuera del directorio nacional'
                        : 'No pudimos comprobar la cobertura',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    covered == false
                        ? 'El directorio de salud y ayuda está disponible en todo el Perú. Revisa tu ubicación para consultar lugares cercanos.'
                        : 'Actualiza la consulta para volver a intentarlo. Esto no significa que tu ciudad esté fuera de cobertura.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
