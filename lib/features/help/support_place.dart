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
  final String? phone, institution, classification;
  final List<String> phones, photoUrls;
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
    this.institution,
    this.classification,
    this.phones = const [],
    this.photoUrls = const [],
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'address': address,
    'district': district,
    'source_url': source,
    'location_source_url': locationSource,
    'reviewed_at': reviewed,
    'latitude': latitude,
    'longitude': longitude,
    'phone': phone,
    'institution': institution,
    'classification': classification,
    'phones': phones,
    'photo_urls': photoUrls,
  };
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
    institution: data['institution'] as String?,
    classification: data['classification'] as String?,
    phones: List<String>.from(data['phones'] as List? ?? const []),
    photoUrls: List<String>.from(data['photo_urls'] as List? ?? const []),
  );

  List<String> get contactPhones => {
    if (phone != null && phone!.isNotEmpty) phone!,
    ...phones,
  }.where((number) => RegExp(r'^\+?[0-9]{3,15}$').hasMatch(number)).toList();
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
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          place.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (place.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              place.photoUrls.first,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              semanticLabel: 'Foto de ${place.name}',
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (final number in place.contactPhones)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final opened = await launchUrl(
                    Uri(scheme: 'tel', path: number),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir el teléfono.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.call_outlined),
                label: Text('Llamar · $number'),
              ),
            ),
          ),
        if (place.contactPhones.isEmpty)
          Text(
            'Teléfono no disponible',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
  );
}
