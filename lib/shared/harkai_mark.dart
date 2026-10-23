import 'package:flutter/material.dart';
import '../core/theme.dart';

/// The Harkai shield, drawn as vectors so it has no app-icon background.
class HarkaiMark extends StatelessWidget {
  const HarkaiMark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Harkai',
    image: true,
    child: const SizedBox(
      width: 30,
      height: 38,
      child: CustomPaint(painter: _HarkaiMarkPainter()),
    ),
  );
}

class _HarkaiMarkPainter extends CustomPainter {
  const _HarkaiMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 240, size.height / 300);
    final bright = Paint()..color = green;
    final muted = Paint()..color = green.withValues(alpha: .58);
    final roof = Path()
      ..moveTo(0, 47)
      ..lineTo(120, 0)
      ..lineTo(240, 47)
      ..lineTo(240, 101)
      ..lineTo(219, 101)
      ..lineTo(219, 61)
      ..lineTo(120, 23)
      ..lineTo(21, 61)
      ..lineTo(21, 101)
      ..lineTo(0, 101)
      ..close();
    canvas.drawPath(roof, muted);
    canvas.drawPath(
      Path()
        ..moveTo(0, 47)
        ..lineTo(59, 24)
        ..lineTo(59, 46)
        ..lineTo(21, 61)
        ..lineTo(21, 101)
        ..lineTo(0, 101)
        ..close(),
      bright,
    );
    canvas.drawPath(
      Path()
        ..moveTo(181, 24)
        ..lineTo(240, 47)
        ..lineTo(240, 101)
        ..lineTo(219, 101)
        ..lineTo(219, 61)
        ..lineTo(181, 46)
        ..close(),
      bright,
    );
    canvas.drawRect(const Rect.fromLTWH(0, 129, 240, 24), bright);
    canvas.drawPath(
      Path()
        ..moveTo(58, 82)
        ..lineTo(79, 73)
        ..lineTo(79, 253)
        ..lineTo(58, 236)
        ..close(),
      bright,
    );
    canvas.drawPath(
      Path()
        ..moveTo(161, 73)
        ..lineTo(182, 82)
        ..lineTo(182, 236)
        ..lineTo(161, 253)
        ..close(),
      bright,
    );
    canvas.drawPath(
      Path()
        ..moveTo(107, 66)
        ..lineTo(120, 60)
        ..lineTo(133, 66)
        ..lineTo(133, 101)
        ..lineTo(107, 101)
        ..close(),
      muted,
    );
    canvas.drawPath(
      Path()
        ..moveTo(107, 173)
        ..lineTo(133, 173)
        ..lineTo(133, 282)
        ..lineTo(120, 295)
        ..lineTo(107, 282)
        ..close(),
      muted,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 180)
        ..lineTo(22, 168)
        ..cubicTo(42, 223, 77, 258, 120, 275)
        ..cubicTo(163, 258, 198, 223, 218, 168)
        ..lineTo(240, 180)
        ..cubicTo(215, 238, 173, 278, 120, 300)
        ..cubicTo(67, 278, 25, 238, 0, 180)
        ..close(),
      muted,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 180)
        ..lineTo(22, 168)
        ..lineTo(33, 189)
        ..lineTo(12, 201)
        ..close(),
      bright,
    );
  }

  @override
  bool shouldRepaint(covariant _HarkaiMarkPainter oldDelegate) => false;
}
