import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
  Widget build(BuildContext context) => Column(
    children: [
      OutlinedButton.icon(
        onPressed: busy ? null : onLocate,
        icon: const Icon(Icons.my_location),
        label: const Text('Ubicarme aquí'),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 250,
        child: CommunityMap(
          center: LatLng(
            double.tryParse(draft.latitude.text) ?? -12.0464,
            double.tryParse(draft.longitude.text) ?? -77.0428,
          ),
          onPoint: onPoint,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Toca el mapa o ingresa el lugar del hecho. El punto inicial no es tu ubicación.',
      ),
      const SizedBox(height: 18),
      AppField(
        label: 'Latitud del hecho',
        controller: draft.latitude,
        keyboard: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        validator: (v) => coordinateValidator(v, -90, 90),
      ),
      AppField(
        label: 'Longitud del hecho',
        controller: draft.longitude,
        keyboard: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        validator: (v) => coordinateValidator(v, -180, 180),
      ),
      AppField(
        label: 'Distrito (opcional)',
        controller: draft.district,
        maxLength: 100,
      ),
      AppField(
        label: 'Ciudad (opcional)',
        controller: draft.city,
        maxLength: 100,
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : onPhoto,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(draft.photoName ?? 'Agregar foto de evidencia'),
      ),
      const Text('JPG o PNG · hasta 5 MB · revisión antes de publicar'),
      if (draft.needsPhoto && draft.mediaId == null)
        const MessageCard(
          'Mascotas y lugares de ayuda necesitan una foto aprobada.',
        ),
      const SizedBox(height: 18),
      AppField(
        label: draft.needsPhoto
            ? 'Contacto (necesario)'
            : 'Contacto (opcional)',
        controller: draft.contact,
        maxLength: 40,
        validator: (v) => draft.needsPhoto && (v?.trim().length ?? 0) < 6
            ? 'Agrega un contacto válido.'
            : null,
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Acepto mostrar este contacto públicamente'),
        value: draft.shareContact,
        onChanged: busy ? null : (v) => onShare(v ?? false),
      ),
    ],
  );
}
