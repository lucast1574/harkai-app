import 'dart:ui';
import 'package:flutter/material.dart';

/// Bounded blur lets the basemap show through without competing with labels.
class MapGlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? accent;
  const MapGlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.accent,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const ink = Color(0xff031521);
    final tint = accent == null
        ? ink
        : Color.alphaBlend(accent!.withValues(alpha: .19), ink);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        tint.withValues(alpha: accent == null ? 0.72 : 0.85),
                        tint.withValues(alpha: accent == null ? 0.84 : 0.93),
                      ]
                    : [
                        Colors.white.withValues(alpha: .90),
                        Colors.white.withValues(alpha: .84),
                      ],
              ),
              border: Border.all(
                color:
                    accent?.withValues(alpha: dark ? 0.48 : 0.55) ??
                    (dark
                        ? Colors.white.withValues(alpha: .12)
                        : Colors.black.withValues(alpha: .06)),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
