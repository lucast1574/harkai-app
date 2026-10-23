import 'package:flutter/material.dart';

class UserLocationMarker extends StatefulWidget {
  final bool fresh;
  const UserLocationMarker({super.key, required this.fresh});
  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updatePulse();
  }

  @override
  void didUpdateWidget(covariant UserLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    updatePulse();
  }

  void updatePulse() {
    if (widget.fresh &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      pulse.repeat(reverse: true);
    } else {
      pulse.stop();
      pulse.value = 0;
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: widget.fresh ? 'Tu ubicación actual' : 'Última ubicación conocida',
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.fresh)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) => Transform.scale(
                scale: .70 + Curves.easeInOut.transform(pulse.value) * .30,
                child: Opacity(opacity: .45 + pulse.value * .55, child: child),
              ),
              child: const SizedBox(
                width: 108,
                height: 108,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x992563eb),
                        Color(0x662563eb),
                        Color(0x002563eb),
                      ],
                      stops: [0, .55, 1],
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.fresh
                  ? const Color(0xff2563eb)
                  : const Color(0xff64748b),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    ),
  );
}
