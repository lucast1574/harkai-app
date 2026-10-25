import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'map_glass_surface.dart';
import '../reports/report_categories.dart';

/// Filters reports around the current GPS position; never changes the area.
class MapCategoryFilters extends StatelessWidget {
  final String selected;
  final int count;
  final bool embedded;
  final ValueChanged<String> onChanged;
  const MapCategoryFilters({
    super.key,
    required this.selected,
    required this.count,
    this.embedded = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: mapReportTypes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final type = index == 0 ? '' : mapReportTypes[index - 1];
          final visual = categoryVisual(type);
          final active = selected == type;
          final accent = type.isEmpty ? green : visual.color;
          return Center(
            child: Semantics(
              selected: active,
              button: true,
              child: Material(
                color: active
                    ? accent.withValues(alpha: dark ? .25 : .14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () => onChanged(type),
                  borderRadius: BorderRadius.circular(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (type.isNotEmpty) ...[
                            Icon(
                              visual.icon,
                              size: 15,
                              color: Color.lerp(
                                visual.color,
                                dark ? Colors.white : visual.color,
                                dark ? .18 : 0,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            type.isEmpty ? 'Todas ($count)' : visual.shortLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active && type.isEmpty
                                  ? (dark ? green : const Color(0xff21643b))
                                  : dark
                                  ? Colors.white.withValues(
                                      alpha: active ? 1 : .84,
                                    )
                                  : colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return embedded
        ? content
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: MapGlassSurface(neutral: true, radius: 24, child: content),
          );
  }
}
