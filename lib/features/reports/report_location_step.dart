import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../map/community_map.dart';
import 'report_draft.dart';

class ReportLocationStep extends StatelessWidget {
  final ReportDraft draft;
  final bool busy;
  final VoidCallback onLocate, onPhoto;
  final ValueChanged<LatLng> onPoint;
  final ValueChanged<bool> onShare;
  const ReportLocationStep({
    super.key,
    required this.draft,
    required this.busy,
    required this.onLocate,
    required this.onPhoto,
    required this.onPoint,
    required this.onShare,
  });
  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      double.tryParse(draft.latitude.text) ?? -12.0464,
      double.tryParse(draft.longitude.text) ?? -77.0428,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Toca el mapa para ajustar el punto exacto',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : onLocate,
              icon: const Icon(Icons.my_location_rounded, size: 17),
              label: const Text('Mi GPS'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: CommunityMap(center: center, onPoint: onPoint),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppField(
                label: 'Distrito (opcional)',
                controller: draft.district,
                maxLength: 100,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppField(
                label: 'Ciudad (opcional)',
                controller: draft.city,
                maxLength: 100,
              ),
            ),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Coordenadas GPS del punto seleccionado',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${draft.latitude.text}, ${draft.longitude.text}',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: AppField(
                    label: 'Latitud',
                    controller: draft.latitude,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => coordinateValidator(v, -90, 90),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppField(
                    label: 'Longitud',
                    controller: draft.longitude,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => coordinateValidator(v, -180, 180),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: draft.mediaId != null
                ? green.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: draft.mediaId != null ? green : const Color(0xffcbd5e1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    draft.mediaId != null
                        ? Icons.check_circle_rounded
                        : Icons.camera_alt_outlined,
                    color: draft.mediaId != null
                        ? const Color(0xff16794b)
                        : navy,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      draft.photoName ?? 'Evidencia fotográfica',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onPhoto,
                    child: Text(
                      draft.mediaId != null ? 'Cambiar foto' : 'Subir foto',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                draft.needsPhoto
                    ? 'Obligatoria para mascotas y lugares de ayuda (JPG o PNG hasta 5 MB).'
                    : 'Opcional · JPG o PNG hasta 5 MB · moderación automática.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppField(
          label: draft.needsPhoto
              ? 'Teléfono o contacto (obligatorio)'
              : 'Teléfono o contacto (opcional)',
          controller: draft.contact,
          maxLength: 40,
          validator: (v) => draft.needsPhoto && (v?.trim().length ?? 0) < 6
              ? 'Agrega un contacto válido.'
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Acepto mostrar este contacto públicamente en el reporte',
            style: TextStyle(fontSize: 13.5),
          ),
          value: draft.shareContact,
          onChanged: busy ? null : (v) => onShare(v ?? false),
        ),
      ],
    );
  }
}
