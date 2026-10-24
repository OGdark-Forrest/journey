import 'package:material_ui/material_ui.dart';

import '../../../shared/theme/palette.dart';

/// Static otter lying on its belly, one paw resting on its head, looking at
/// the viewer. Decorative only (skipped by screen readers).
///
/// TODO(design): placeholder vector art. Swap for a real illustration asset
/// when design has one; keep this widget's API.
class RestingOtter extends StatelessWidget {
  const RestingOtter({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: width * 0.55,
          child: const CustomPaint(painter: _RestingOtterPainter()),
        ),
      ),
    );
  }
}

class _RestingOtterPainter extends CustomPainter {
  const _RestingOtterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // All coordinates are fractions of the width.
    final w = size.width;
    Offset p(double x, double y) => Offset(x * w, y * w);
    Rect oval(double cx, double cy, double ow, double oh) =>
        Rect.fromCenter(center: p(cx, cy), width: ow * w, height: oh * w);

    final fur = Paint()..color = Palette.otterFur;
    final furDark = Paint()..color = Palette.otterFurDark;
    final muzzle = Paint()..color = Palette.otterMuzzle;
    final ink = Paint()..color = Palette.otterNose;
    final line = Paint()
      ..color = Palette.otterNose
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.007 * w;

    // Ground shadow
    canvas.drawOval(oval(0.47, 0.515, 0.80, 0.05), Paint()..color = const Color(0x14000000));

    // Tail, curling out to the left
    final tail = Path()
      ..moveTo(0.19 * w, 0.40 * w)
      ..quadraticBezierTo(0.03 * w, 0.42 * w, 0.03 * w, 0.49 * w)
      ..quadraticBezierTo(0.10 * w, 0.505 * w, 0.21 * w, 0.475 * w)
      ..close();
    canvas.drawPath(tail, furDark);

    // Back foot
    canvas.drawOval(oval(0.19, 0.49, 0.11, 0.05), furDark);

    // Body, lying flat
    canvas.drawOval(oval(0.42, 0.42, 0.56, 0.19), fur);
    // Lighter chest near the head
    canvas.drawOval(oval(0.60, 0.45, 0.15, 0.10), Paint()..color = Palette.otterMuzzle.withValues(alpha: 0.55));

    // Front paw resting on the ground
    canvas.drawOval(oval(0.60, 0.50, 0.12, 0.045), furDark);
    for (final dx in [-0.02, 0.0, 0.02]) {
      canvas.drawLine(p(0.62 + dx, 0.492), p(0.62 + dx, 0.505), line..color = Palette.otterMuzzle.withValues(alpha: 0.7));
    }
    line.color = Palette.otterNose;

    // Head, facing the viewer
    const cx = 0.73, cy = 0.30;
    for (final dx in [-0.13, 0.13]) {
      canvas.drawCircle(p(cx + dx, cy - 0.08), 0.028 * w, furDark);
      canvas.drawCircle(p(cx + dx, cy - 0.08), 0.014 * w, muzzle);
    }
    canvas.drawOval(oval(cx, cy, 0.30, 0.24), fur);
    canvas.drawOval(oval(cx, cy - 0.07, 0.10, 0.04), Paint()..color = Palette.otterMuzzle.withValues(alpha: 0.22));

    // Blush
    final blush = Paint()..color = Palette.otterBlush.withValues(alpha: 0.5);
    for (final dx in [-0.08, 0.08]) {
      canvas.drawOval(oval(cx + dx, cy + 0.025, 0.04, 0.024), blush);
    }

    // Muzzle
    canvas.drawOval(oval(cx, cy + 0.04, 0.15, 0.095), muzzle);

    // Eyes: open, looking straight out
    for (final dx in [-0.05, 0.05]) {
      final c = p(cx + dx, cy - 0.02);
      canvas.drawCircle(c, 0.015 * w, ink);
      canvas.drawCircle(c.translate(-0.005 * w, -0.005 * w), 0.0055 * w, Paint()..color = Colors.white);
    }

    // Nose
    canvas.drawRRect(
      RRect.fromRectAndRadius(oval(cx, cy + 0.014, 0.038, 0.024), Radius.circular(0.012 * w)),
      ink,
    );

    // Small contented smile
    canvas.drawLine(p(cx, cy + 0.026), p(cx, cy + 0.042), line);
    canvas.drawPath(
      Path()
        ..moveTo(cx * w - 0.024 * w, cy * w + 0.042 * w)
        ..quadraticBezierTo(cx * w, cy * w + 0.062 * w, cx * w + 0.024 * w, cy * w + 0.042 * w),
      line,
    );

    // Whiskers
    final whisker = Paint()
      ..color = Palette.otterFurDark.withValues(alpha: 0.6)
      ..strokeWidth = 0.004 * w
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(
          p(cx + side * 0.055, cy + 0.035 + i * 0.01),
          p(cx + side * 0.115, cy + 0.028 + i * 0.018),
          whisker,
        );
      }
    }

    // Raised arm hugging the side of the head, paw resting on top of it.
    canvas.drawPath(
      Path()
        ..moveTo(0.605 * w, 0.40 * w)
        ..quadraticBezierTo(0.545 * w, 0.25 * w, 0.655 * w, 0.185 * w),
      Paint()
        ..color = Palette.otterFurDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.048 * w
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(oval(0.67, 0.18, 0.075, 0.048), furDark);
    final toe = Paint()
      ..color = Palette.otterMuzzle.withValues(alpha: 0.7)
      ..strokeWidth = 0.004 * w
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.015, 0.003, 0.021]) {
      canvas.drawLine(p(0.67 + dx, 0.192), p(0.67 + dx + 0.004, 0.2), toe);
    }
  }

  @override
  bool shouldRepaint(_RestingOtterPainter oldDelegate) => false;
}
