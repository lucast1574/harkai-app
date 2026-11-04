import 'package:flutter/material.dart';

class DirectoryPhoto extends StatelessWidget {
  final String? url;
  final IconData fallback;
  final String label;
  const DirectoryPhoto({
    super.key,
    this.url,
    required this.fallback,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Icon(fallback, size: 28, color: colors.onSurfaceVariant),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 96,
        child: url?.isNotEmpty == true
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: 352,
                semanticLabel: label,
                loadingBuilder: (context, image, progress) =>
                    progress == null ? image : placeholder,
                errorBuilder: (context, error, stack) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}

String nearbyDistanceLabel(double meters) => meters < 1000
    ? '${(meters / 10).round() * 10} m'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
