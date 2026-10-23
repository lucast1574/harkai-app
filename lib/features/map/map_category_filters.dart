import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../reports/report_categories.dart';

/// Filters reports around the current GPS position; never changes the area.
class MapCategoryFilters extends StatelessWidget {
  final String selected;
  final int count;
  final ValueChanged<String> onChanged;
  const MapCategoryFilters({
    super.key,
    required this.selected,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: mapReportTypes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = index == 0 ? '' : mapReportTypes[index - 1];
          final visual = categoryVisual(type);
          final active = selected == type;
          final background = active
              ? (type.isEmpty ? navy : visual.color)
              : colors.surface;
          return Center(
            child: Material(
              color: background.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => onChanged(type),
                borderRadius: BorderRadius.circular(24),
                child: Semantics(
                  selected: active,
                  button: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (type.isNotEmpty) ...[
                          Icon(
                            visual.icon,
                            size: 17,
                            color: active ? Colors.white : visual.color,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          type.isEmpty ? 'Todas ($count)' : visual.shortLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
