import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/directory_photo.dart';

class PetCard extends StatelessWidget {
  final Incident incident;
  final LatLng origin;
  final VoidCallback onOpen;
  const PetCard({
    super.key,
    required this.incident,
    required this.origin,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DirectoryPhoto(
                url: incident.mediaId == null
                    ? null
                    : '${ApiClient.baseUrl}/v1/media/${incident.mediaId}',
                fallback: Icons.pets_outlined,
                label: 'Foto del aviso de mascota',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      incident.status == 'resolved'
                          ? 'Caso resuelto'
                          : incident.verificationLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${incident.district ?? incident.city ?? 'Ver ubicación'} · A ${nearbyDistanceLabel(const Distance()(origin, LatLng(incident.latitude, incident.longitude)))}',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
