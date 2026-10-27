import 'package:flutter/material.dart';
import '../../core/theme.dart';

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
      if (!pulse.isAnimating) pulse.repeat();
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
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, child) => CustomPaint(
                  size: const Size.square(108),
                  painter: _LocationRadar(
                    progress: pulse.value,
                    animate: pulse.isAnimating,
                  ),
                ),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.fresh ? green : const Color(0xff64748b),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person_rounded, color: navy, size: 17),
          ),
        ],
      ),
    ),
  );
}

class _LocationRadar extends CustomPainter {
  final double progress;
  final bool animate;
  const _LocationRadar({required this.progress, required this.animate});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      26,
      Paint()..color = green.withValues(alpha: .13),
    );
    for (var i = 0; i < 2; i++) {
      final phase = animate ? (progress + i * .5) % 1 : .35 + i * .4;
      canvas.drawCircle(
        center,
        17 + phase * 35,
        Paint()
          ..color = green.withValues(alpha: (1 - phase) * .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LocationRadar oldDelegate) =>
      progress != oldDelegate.progress || animate != oldDelegate.animate;
}
