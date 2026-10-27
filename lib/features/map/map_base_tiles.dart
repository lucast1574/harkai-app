import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tone only base tiles; reports, businesses and location keep their colors.
class MapBaseTiles extends StatelessWidget {
  final bool dark;
  const MapBaseTiles({super.key, required this.dark});

  // Map tile luminance to Harkai navy while keeping labels readable.
  static const darkPalette = ColorFilter.matrix([
    -.070,
    -.236,
    -.024,
    0,
    99,
    -.079,
    -.266,
    -.027,
    0,
    117,
    -.085,
    -.286,
    -.029,
    0,
    140,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: const String.fromEnvironment(
        'HARKAI_TILE_URL',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      userAgentPackageName: 'com.lucast.harkai',
    );
    return dark ? ColorFiltered(colorFilter: darkPalette, child: tiles) : tiles;
  }
}
