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

  String get kindLabel => switch (kind) {
    'police' => 'Comisaría',
    'fire_station' => 'Estación de bomberos',
    'hospital' => 'Hospital o clínica',
    'health_center' => 'Centro de salud',
    _ => 'Lugar de apoyo',
  };
  IconData get kindIcon => switch (kind) {
    'police' => Icons.local_police_rounded,
    'fire_station' => Icons.local_fire_department_rounded,
    'support' => Icons.support_rounded,
    _ => Icons.add_rounded,
  };
  Color get markerColor => switch (kind) {
    'police' => const Color(0xff2563a6),
    'fire_station' => const Color(0xffb95016),
    _ => const Color(0xffd94750),
  };

  List<String> get contactPhones => {
    if (phone != null && phone!.isNotEmpty) phone!,
    ...phones,
  }.where((number) => RegExp(r'^\+?[0-9]{3,15}$').hasMatch(number)).toList();
}

class SupportPlaceDetails extends StatelessWidget {
  final SupportPlace place;
  final VoidCallback? onClose;
  const SupportPlaceDetails({super.key, required this.place, this.onClose});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (onClose != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Cerrar ficha',
                      padding: EdgeInsets.zero,
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(place.kindIcon, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                place.kindLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            place.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (place.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                place.photoUrls.first,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de ${place.name}',
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (place.address.isNotEmpty || place.district.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      place.address,
                      place.district,
                    ].where((part) => part.isNotEmpty).join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
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
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('Llamar · $number'),
                ),
              ),
            ),
          if (place.contactPhones.isEmpty)
            Text(
              'Teléfono no disponible',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
