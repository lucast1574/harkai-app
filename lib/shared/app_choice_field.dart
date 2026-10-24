import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppChoiceField extends StatefulWidget {
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String>? onChanged;
  const AppChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  @override
  State<AppChoiceField> createState() => _AppChoiceFieldState();
}

class _AppChoiceFieldState extends State<AppChoiceField> {
  bool opening = false;
  Future<void> open() async {
    if (opening || widget.onChanged == null) return;
    setState(() => opening = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        requestFocus: true,
        builder: (_) => _ChoiceSheet(
          label: widget.label,
          value: widget.value,
          options: Map.of(widget.options),
        ),
      );
      if (mounted && selected != null && widget.options.containsKey(selected)) {
        widget.onChanged?.call(selected);
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    tileColor: Theme.of(context).colorScheme.surfaceContainer,
    title: Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(
      widget.options[widget.value] ?? 'Seleccionar',
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    trailing: const Icon(Icons.expand_more_rounded),
    enabled: widget.onChanged != null,
    onTap: widget.onChanged == null ? null : open,
  );
}

class _ChoiceSheet extends StatefulWidget {
  final String label, value;
  final Map<String, String> options;
  const _ChoiceSheet({
    required this.label,
    required this.value,
    required this.options,
  });
  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late final entries = widget.options.entries.toList();
  late int active = entries
      .indexWhere((e) => e.key == widget.value)
      .clamp(0, entries.isEmpty ? 0 : entries.length - 1);
  late final keys = List.generate(entries.length, (_) => GlobalKey());
  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (entries.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      Navigator.pop(context, entries[active].key);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () => active =
            (active +
                    (event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1))
                .clamp(0, entries.length - 1),
      );
      final target = keys[active].currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: Duration.zero);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      child: Focus(
        autofocus: true,
        onKeyEvent: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: entries.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    key: keys[i],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(entries[i].value),
                    selected: entries[i].key == widget.value,
                    tileColor: i == active
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: .45)
                        : null,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    trailing: entries[i].key == widget.value
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, entries[i].key),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
