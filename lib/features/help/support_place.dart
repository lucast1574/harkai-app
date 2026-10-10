import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPlace {
  final String id,
      name,
      kind,
      address,
      district,
      source,
      locationSource,
      reviewed;
  final String? phone;
  final double latitude, longitude;
  const SupportPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    required this.district,
    required this.source,
    required this.locationSource,
    required this.reviewed,
    required this.latitude,
    required this.longitude,
    this.phone,
  });
  factory SupportPlace.fromJson(Map<String, dynamic> data) => SupportPlace(
    id: data['id'] as String,
    name: data['name'] as String,
    kind: data['kind'] as String,
    address: data['address'] as String,
    district: data['district'] as String,
    source: data['source_url'] as String,
    locationSource: data['location_source_url'] as String,
    reviewed: data['reviewed_at'] as String,
    latitude: (data['latitude'] as num).toDouble(),
    longitude: (data['longitude'] as num).toDouble(),
    phone: data['phone'] as String?,
  );
}

class SupportPlaceDetails extends StatelessWidget {
  final SupportPlace place;
  const SupportPlaceDetails({super.key, required this.place});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text('${place.address} · ${place.district}'),
        const SizedBox(height: 12),
        const Text(
          'Directorio de salud. No es una alerta. Ubicación de referencia; consulta disponibilidad y condiciones antes de acudir.',
        ),
        if (place.phone != null && place.phone!.isNotEmpty)
          TextButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: place.phone)),
            icon: const Icon(Icons.phone_outlined),
            label: Text('Contacto institucional: ${place.phone}'),
          ),
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(place.source),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Fuente institucional'),
        ),
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse(place.locationSource),
            mode: LaunchMode.externalApplication,
          ),
          child: const Text('Fuente de ubicación'),
        ),
        Text(
          'Fuentes consultadas: ${place.reviewed}. Para emergencias médicas consulta el SAMU; el contacto institucional no sustituye una línea de urgencias.',
        ),
      ],
    ),
  );
}
