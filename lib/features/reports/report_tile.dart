import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';

class ReportTile extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;
  const ReportTile({super.key, required this.incident, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppScope.of(context).categoryLabel(incident.type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_outward, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              incident.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            VerificationBadge(incident.verified),
            const SizedBox(height: 8),
            Text(
              incident.district ??
                  incident.city ??
                  'Ubicación indicada en el mapa',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
