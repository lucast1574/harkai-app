import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'report_categories.dart';

/// Reporting actions live here; map chips only filter existing reports.
class MapReportSheet extends StatefulWidget {
  final ValueChanged<String> onReport;
  final VoidCallback onEmergency, onHelp;
  final List<Widget> children;
  const MapReportSheet({
    super.key,
    required this.onReport,
    required this.onEmergency,
    required this.onHelp,
    required this.children,
  });

  @override
  State<MapReportSheet> createState() => _MapReportSheetState();
}

class _MapReportSheetState extends State<MapReportSheet> {
  final contentKey = GlobalKey();
  double? contentHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onReport = widget.onReport;
    final onEmergency = widget.onEmergency;
    final onHelp = widget.onHelp;
    final children = widget.children;
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box =
              contentKey.currentContext?.findRenderObject() as RenderBox?;
          if (!mounted || box == null || !box.hasSize) return;
          final height = box.size.height;
          if (contentHeight == null || (contentHeight! - height).abs() > 1) {
            setState(() => contentHeight = height);
          }
        });
        final maximum = ((contentHeight ?? 420) / constraints.maxHeight).clamp(
          .22,
          .65,
        );
        final minimum = (110 / constraints.maxHeight).clamp(.10, maximum);
        return DraggableScrollableSheet(
          initialChildSize: maximum,
          minChildSize: minimum,
          maxChildSize: maximum,
          snap: true,
          snapSizes: [minimum, maximum],
          expand: false,
          builder: (context, controller) => Material(
            color: colors.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: .12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    key: contentKey,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.onSurface.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '¿Qué está pasando?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elige una categoría para reportar en tu zona.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ReportAction(
                          type: 'crime',
                          expanded: true,
                          onTap: () => onReport('crime'),
                        ),
                        const SizedBox(height: 8),
                        for (var row = 0; row < 2; row++) ...[
                          Row(
                            children: [
                              for (var col = 0; col < 2; col++) ...[
                                if (col > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _ReportAction(
                                    type: mapReportTypes[1 + row * 2 + col],
                                    onTap: () => onReport(
                                      mapReportTypes[1 + row * 2 + col],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 64,
                                child: OutlinedButton.icon(
                                  onPressed: onEmergency,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.onSurface,
                                    side: BorderSide(
                                      color: colors.onSurface.withValues(
                                        alpha: .12,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.phone_in_talk_outlined,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Emergencias',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _HarkiHelpAction(onTap: onHelp)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...children,
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportAction extends StatelessWidget {
  final String type;
  final bool expanded;
  final VoidCallback onTap;
  const _ReportAction({
    required this.type,
    this.expanded = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(type);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: expanded ? visual.color : colors.onSurface.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                visual.icon,
                size: 24,
                color: expanded ? Colors.white : visual.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visual.shortLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: expanded ? Colors.white : colors.onSurface,
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Robos, extorsiones, secuestros y violencia',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              if (expanded)
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _HarkiHelpAction extends StatelessWidget {
  final VoidCallback onTap;
  const _HarkiHelpAction({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.onSurface.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/bot.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harki',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ayuda',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
