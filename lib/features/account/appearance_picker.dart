import 'package:flutter/material.dart';

class AppearancePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const AppearancePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apariencia',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final entry in const {
                'system': 'Sistema',
                'light': 'Claro',
                'dark': 'Oscuro',
              }.entries) ...[
                if (entry.key != 'system') const SizedBox(width: 10),
                Expanded(
                  child: _AppearanceOption(
                    mode: entry.key,
                    label: entry.value,
                    selected: value == entry.key,
                    onTap: () => onChanged(entry.key),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class _AppearanceOption extends StatelessWidget {
  final String mode, label;
  final bool selected;
  final VoidCallback onTap;
  const _AppearanceOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .55)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  height: 68,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        if (mode != 'dark')
                          const Expanded(child: _ThemePreview(dark: false)),
                        if (mode != 'light')
                          const Expanded(child: _ThemePreview(dark: true)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 17,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final bool dark;
  const _ThemePreview({required this.dark});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: dark ? const Color(0xff071b30) : const Color(0xffeef3f6),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xff57d463),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xff254153) : Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
