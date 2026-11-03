import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Subtle storefront centered on its location, with a generous touch target.
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
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 34 : 28,
            height: selected ? 34 : 28,
            decoration: BoxDecoration(
              color: selected ? navy : const Color(0xe6245b8f),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? green : Colors.white,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20011935),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.storefront_outlined,
              color: selected ? green : Colors.white,
              size: selected ? 20 : 17,
            ),
          ),
        ),
      ),
    ),
  );
}
