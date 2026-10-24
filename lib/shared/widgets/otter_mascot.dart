import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/models/happiness.dart';
import '../theme/palette.dart';

/// The otter mascot. Its face reacts to [mood] (1-5, the happiness scale).
///
/// TODO(design): placeholder vector art drawn with CustomPainter. Swap the
/// painter for real otter illustrations (e.g. Rive/Lottie with a `mood` input)
/// when design assets exist; keep this widget's API so callers don't change.
class OtterMascot extends StatefulWidget {
  const OtterMascot({super.key, this.mood = Happiness.neutral, this.size = 96, this.animate = true});

  final int mood;
  final double size;

  /// Gentle bob + blink. Off for small/static uses (lists, pickers).
  final bool animate;

  @override
  State<OtterMascot> createState() => _OtterMascotState();
}

class _OtterMascotState extends State<OtterMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(OtterMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduceMotion) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Otter looking ${Happiness.phrase(widget.mood)}',
      child: SizedBox.square(
        dimension: widget.size,
        // Animate between expressions instead of snapping.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.mood.toDouble()),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, mood, _) => AnimatedBuilder(
            animation: _idle,
            builder: (context, _) {
              final t = _idle.value;
              final bob = widget.animate ? math.sin(t * 2 * math.pi) : 0.0;
              // Quick blink near the end of each 4s loop.
              final blink = (t > 0.90 && t < 0.96) ? 1 - ((t - 0.93).abs() / 0.03) : 0.0;
              return CustomPaint(
                painter: _OtterPainter(mood: mood, bob: bob, blink: blink.clamp(0.0, 1.0)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OtterPainter extends CustomPainter {
  _OtterPainter({required this.mood, required this.bob, required this.blink});

  /// 1-5, may be fractional mid-transition.
  final double mood;

  /// -1..1 vertical idle offset.
  final double bob;

  /// 0 = open, 1 = closed.
  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height * 0.56 + bob * s * 0.015;

    // -1 (rough) .. 0 (okay) .. 1 (great)
    final k = ((mood - 3) / 2).clamp(-1.0, 1.0);

    final fur = Paint()..color = Palette.otterFur;
    final furDark = Paint()..color = Palette.otterFurDark;
    final muzzle = Paint()..color = Palette.otterMuzzle;
    final ink = Paint()..color = Palette.otterNose;

    // Ears: small and set low on the sides (high round ears read as a bear).
    for (final dx in [-0.39, 0.39]) {
      final ear = Offset(cx + dx * s, cy - 0.15 * s);
      canvas.drawCircle(ear, 0.065 * s, furDark);
      canvas.drawCircle(ear, 0.032 * s, muzzle);
    }

    // Head: wide and a little flat.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.86 * s, height: 0.64 * s), fur);
    // Lighter brow patch, a common otter marking.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 0.20 * s), width: 0.30 * s, height: 0.12 * s),
      Paint()..color = Palette.otterMuzzle.withValues(alpha: 0.22),
    );

    // Cheek blush when happy
    if (k > 0.2) {
      final blush = Paint()..color = Palette.otterBlush.withValues(alpha: 0.55 * ((k - 0.2) / 0.8));
      for (final dx in [-0.25, 0.25]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + dx * s, cy + 0.07 * s), width: 0.11 * s, height: 0.07 * s),
          blush,
        );
      }
    }

    // Muzzle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 0.11 * s), width: 0.46 * s, height: 0.30 * s),
      muzzle,
    );

    // Eyes
    final eyeY = cy - 0.06 * s;
    final eyeR = 0.045 * s;
    for (final dx in [-0.15, 0.15]) {
      final c = Offset(cx + dx * s, eyeY);
      if (k > 0.75 || blink > 0.6) {
        // Happy "^ ^" eyes (or a blink).
        final arc = Paint()
          ..color = Palette.otterNose
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.028 * s
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(c.dx - eyeR, c.dy + eyeR * 0.3)
          ..quadraticBezierTo(c.dx, c.dy - eyeR * (k > 0.75 ? 1.2 : 0), c.dx + eyeR, c.dy + eyeR * 0.3);
        canvas.drawPath(path, arc);
      } else {
        final openness = 1 - blink;
        canvas.drawOval(
          Rect.fromCenter(center: c, width: eyeR * 2, height: eyeR * 2 * openness.clamp(0.15, 1.0)),
          ink,
        );
        if (openness > 0.5) {
          canvas.drawCircle(
            c.translate(-eyeR * 0.35, -eyeR * 0.35),
            eyeR * 0.32,
            Paint()..color = Colors.white,
          );
        }
      }

      // Worried brows when low
      if (k < -0.2) {
        final brow = Paint()
          ..color = Palette.otterFurDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.025 * s
          ..strokeCap = StrokeCap.round;
        final inner = dx < 0 ? 1.0 : -1.0; // toward the center
        final lift = 0.05 * s * (-k);
        canvas.drawLine(
          Offset(c.dx - inner * eyeR * 1.1, c.dy - eyeR * 1.7),
          Offset(c.dx + inner * eyeR * 0.9, c.dy - eyeR * 1.7 - lift),
          brow,
        );
      }
    }

    // Nose
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 0.035 * s), width: 0.12 * s, height: 0.075 * s),
        Radius.circular(0.04 * s),
      ),
      ink,
    );

    // Mouth: curve up (smile) or down (frown) with mood.
    final mouth = Paint()
      ..color = Palette.otterNose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * s
      ..strokeCap = StrokeCap.round;
    final my = cy + 0.15 * s - k * 0.01 * s;
    final mw = 0.07 * s + 0.03 * s * k.abs();
    canvas.drawLine(Offset(cx, cy + 0.07 * s), Offset(cx, my - k * 0.02 * s), mouth);
    canvas.drawPath(
      Path()
        ..moveTo(cx - mw, my - k * 0.02 * s)
        ..quadraticBezierTo(cx, my + k * 0.07 * s, cx + mw, my - k * 0.02 * s),
      mouth,
    );

    // Whiskers
    final whisker = Paint()
      ..color = Palette.otterFurDark.withValues(alpha: 0.6)
      ..strokeWidth = 0.012 * s
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      for (var i = -1; i <= 1; i++) {
        final start = Offset(cx + side * 0.17 * s, cy + 0.10 * s + i * 0.03 * s);
        final end = Offset(cx + side * 0.34 * s, cy + 0.08 * s + i * 0.05 * s);
        canvas.drawLine(start, end, whisker);
      }
    }
  }

  @override
  bool shouldRepaint(_OtterPainter old) => old.mood != mood || old.bob != bob || old.blink != blink;
}
