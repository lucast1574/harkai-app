import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Compact storefront with a tip anchored to the business coordinates.
class BusinessMapMarker extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const BusinessMapMarker({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Negocio: $name',
    button: true,
    selected: selected,
    child: Tooltip(
      message: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: 4,
              child: Transform.rotate(
                angle: .785398,
                child: Container(width: 14, height: 14, color: Colors.white),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? navy : const Color(0xff245b8f),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33011935),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.storefront_outlined,
                color: selected ? green : Colors.white,
                size: 26,
              ),
            ),
            Positioned(
              top: 3,
              right: 5,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
