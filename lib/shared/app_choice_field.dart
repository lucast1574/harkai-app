import 'package:flutter/material.dart';

/// Touch friendly selector using the same sheet and selection style as the app.
class AppChoiceField extends StatelessWidget {
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    tileColor: Theme.of(context).colorScheme.surfaceContainer,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(
      options[value] ?? 'Seleccionar',
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    trailing: const Icon(Icons.expand_more_rounded),
    enabled: onChanged != null,
    onTap: onChanged == null
        ? null
        : () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              builder: (sheetContext) => FocusTraversalGroup(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  children: [
                    ListTile(
                      title: Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    for (final option in options.entries)
                      ListTile(
                        title: Text(option.value),
                        selected: value == option.key,
                        autofocus: value == option.key,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        trailing: value == option.key
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, option.key),
                      ),
                  ],
                ),
              ),
            );
            if (selected != null) onChanged?.call(selected);
          },
  );
}
