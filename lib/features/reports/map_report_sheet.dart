import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'report_categories.dart';

/// Reporting actions live here; map chips only filter existing reports.
class MapReportSheet extends StatefulWidget {
  final ValueChanged<String> onReport;
  final VoidCallback onEmergency;
  final List<Widget> children;
  const MapReportSheet({
    super.key,
    required this.onReport,
    required this.onEmergency,
    required this.children,
  });

  @override
  State<MapReportSheet> createState() => _MapReportSheetState();
}

class _MapReportSheetState extends State<MapReportSheet> {
  final contentKey = GlobalKey();
  final sheetController = DraggableScrollableController();
  double? contentHeight;

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onReport = widget.onReport;
    final onEmergency = widget.onEmergency;
    final children = widget.children;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        if (!availableHeight.isFinite || availableHeight <= 0) {
          return const SizedBox.shrink();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box =
              contentKey.currentContext?.findRenderObject() as RenderBox?;
          if (!mounted || box == null || !box.hasSize) return;
          final height = box.size.height;
          if (contentHeight == null || (contentHeight! - height).abs() > 1) {
            setState(() => contentHeight = height);
          }
        });
        final maximum = ((contentHeight ?? 420) / availableHeight).clamp(
          .22,
          .65,
        );
        final minimum = (110 / availableHeight).clamp(.10, maximum);
        return DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: minimum,
          minChildSize: minimum,
          maxChildSize: maximum,
          // Flutter includes both endpoints automatically. A short viewport
          // can make them equal, in which case there is nothing to snap to.
          snap: minimum < maximum,
          expand: false,
          builder: (context, controller) => Material(
            color: colors.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: .12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    key: contentKey,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) {
                            if (!sheetController.isAttached) return;
                            sheetController.jumpTo(
                              (sheetController.size -
                                      details.delta.dy / availableHeight)
                                  .clamp(minimum, maximum),
                            );
                          },
                          onVerticalDragEnd: (details) {
                            final target = details.primaryVelocity! < -100
                                ? maximum
                                : details.primaryVelocity! > 100
                                ? minimum
                                : sheetController.size > (minimum + maximum) / 2
                                ? maximum
                                : minimum;
                            sheetController.animateTo(
                              target,
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          onTap: () => sheetController.animateTo(
                            sheetController.size > minimum + .02
                                ? minimum
                                : maximum,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colors.onSurface.withValues(
                                      alpha: .24,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '¿Qué está pasando?',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.5,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  ListenableBuilder(
                                    listenable: sheetController,
                                    builder: (_, _) => Icon(
                                      sheetController.isAttached &&
                                              sheetController.size >
                                                  minimum + .02
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_up_rounded,
                                      semanticLabel:
                                          'Abrir o recoger categorías',
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comparte lo que ves. Ayuda a tu zona.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
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
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: colors.onSurface.withValues(alpha: .08),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: onEmergency,
                            icon: const Icon(
                              Icons.phone_in_talk_outlined,
                              size: 22,
                            ),
                            label: const Text('Llamadas de emergencia'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: colors.primary.withValues(
                                alpha: .12,
                              ),
                              foregroundColor: colors.onSurface,
                            ),
                          ),
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
    final hints = {
      'crime': 'Robo, extorsión o violencia',
      'fire': 'Humo o fuego',
      'emergency': 'Ayuda urgente',
      'crash': 'En la vía',
      'pet': 'Perdidas o vistas',
    };
    final radius = BorderRadius.circular(20);
    return Material(
      color: expanded
          ? Color.alphaBlend(
              visual.color.withValues(alpha: .16),
              colors.surface,
            )
          : colors.onSurface.withValues(alpha: .035),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: expanded
              ? visual.color.withValues(alpha: .45)
              : colors.onSurface.withValues(alpha: .055),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        focusColor: colors.onSurface.withValues(alpha: .10),
        child: Padding(
          padding: EdgeInsets.all(expanded ? 16 : 14),
          child: expanded
              ? Row(
                  children: [
                    _CategoryIcon(type: type, large: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visual.shortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hints[type]!,
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
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _CategoryIcon(type: type),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            visual.shortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hints[type]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String type;
  final bool large;
  const _CategoryIcon({required this.type, this.large = false});
  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(type);
    return Container(
      width: large ? 42 : 32,
      height: large ? 42 : 32,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(large ? 14 : 10),
      ),
      child: Center(
        child: Icon(
          visual.icon,
          size: large ? 25 : 20,
          color: Color.lerp(
            visual.color,
            Theme.of(context).colorScheme.onSurface,
            Theme.of(context).brightness == Brightness.dark ? 0.22 : 0,
          ),
        ),
      ),
    );
  }
}
