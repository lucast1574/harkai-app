import 'package:flutter/material.dart';

class DistrictChatHeader extends StatelessWidget {
  final String? name, province;
  final bool locating;
  final VoidCallback? onChoose, onLocate;
  const DistrictChatHeader({
    super.key,
    this.name,
    this.province,
    required this.locating,
    this.onChoose,
    this.onLocate,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onChoose,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Elegir distrito',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              province?.isNotEmpty == true
                                  ? '$province · Cambiar zona'
                                  : 'Explora cualquier zona',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.expand_more_rounded,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Mi ubicación',
            onPressed: onLocate,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}

class DistrictChatEmpty extends StatelessWidget {
  final String district;
  final VoidCallback? onStart;
  const DistrictChatEmpty({super.key, required this.district, this.onStart});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 34,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu barrio tiene mucho que contar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Abre la conversación en $district. Una pregunta o una novedad puede ayudar a tus vecinos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            if (onStart != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Escribir el primer mensaje'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
