import 'package:flutter/material.dart';
import '../reports/report_detail.dart';
import '../business/business_point.dart';
import '../help/support_place.dart';
import 'map_target.dart';

/// A single scroll controller connects expansion with the full point content.
class MapTargetSheet extends StatelessWidget {
  final MapTarget target;
  final VoidCallback onClose;
  const MapTargetSheet({
    super.key,
    required this.target,
    required this.onClose,
  });
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .38,
    minChildSize: .24,
    maxChildSize: .96,
    snap: true,
    snapSizes: const [.38, .65, .96],
    shouldCloseOnMinExtent: false,
    builder: (context, controller) {
      final header = Column(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  target.incident != null
                      ? 'Reporte en el mapa'
                      : target.businessPoint != null
                      ? 'Lugar promocionado'
                      : 'Lugar de ayuda',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar ficha',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Desliza hacia arriba para ver los detalles',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
        ],
      );
      return Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: target.incident != null
            ? ReportDetail(
                key: ValueKey(target.id),
                id: target.id,
                initialIncident: target.incident,
                embedded: true,
                scrollController: controller,
                sheetHeader: header,
              )
            : ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  header,
                  if (target.businessPoint != null)
                    BusinessDetails(point: target.businessPoint!)
                  else
                    SupportPlaceDetails(place: target.support!),
                ],
              ),
      );
    },
  );
}
