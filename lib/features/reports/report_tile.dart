import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class ReportTile extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;
  const ReportTile({super.key, required this.incident, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(incident.type);
    final locationLabel = [
      if (incident.district != null && incident.district!.trim().isNotEmpty)
        incident.district!.trim(),
      if (incident.city != null && incident.city!.trim().isNotEmpty)
        incident.city!.trim(),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: visual.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CategoryGlyph(
                        type: incident.type,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppScope.of(context).categoryLabel(incident.type),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: Color(0xff64748b),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                locationLabel.isEmpty
                                    ? 'Ubicación en el mapa'
                                    : locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff64748b),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(color: Color(0xff94a3b8)),
                            ),
                            Text(
                              _relativeTime(incident.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xff94a3b8),
                  ),
                ],
              ),
              if (incident.mediaId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      AppScope.of(context).api.photoUrl(incident.mediaId!),
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                incident.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  VerificationBadge(incident.verified),
                  if (incident.mediaId != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffe2e8f0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 12,
                            color: navy,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Foto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
