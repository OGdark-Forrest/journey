import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';

/// Half-circle meter from 0 to 7 days with a fire in the middle. The needle
/// points at [count]; the arc and fire get redder and glow more as it rises.
class HeatGauge extends StatelessWidget {
  const HeatGauge({super.key, required this.count, this.width = 300});

  static const maxDays = 7;

  /// Days logged this week, 0-7.
  final int count;
  final double width;

  /// Gray-beige (0) -> gold -> orange -> red (7). Each step is redder and more
  /// saturated than the one before.
  static Color heatColor(double days) {
    const stops = [Color(0xFFB9AE9F), Color(0xFFE6B25C), Color(0xFFE2793A), Color(0xFFD02F24)];
    final t = (days / maxDays).clamp(0.0, 1.0) * (stops.length - 1);
    final i = t.floor().clamp(0, stops.length - 2);
    return Color.lerp(stops[i], stops[i + 1], t - i)!;
  }

  /// Needle angle in radians: pi (left, 0 days) to 2*pi (right, 7 days).
  static double angleFor(double days) => math.pi + math.pi * (days / maxDays).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final radius = width * 0.38;
    final pivotY = radius + 40; // room for the 0-7 labels above the arc
    final height = pivotY + 14; // "0" and "7" sit level with the pivot

    return Semantics(
      label: '$count of $maxDays days logged this week',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: count.toDouble()),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              final heat = heatColor(v);
              final t = (v / maxDays).clamp(0.0, 1.0);
              final fireSize = radius * (0.48 + 0.22 * t);
              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GaugePainter(
                          value: v,
                          count: count,
                          radius: radius,
                          pivot: Offset(width / 2, pivotY),
                          track: context.jc.secondarySurface,
                          label: context.jc.mutedText,
                          activeLabel: context.cs.onSurface,
                          labelStyle: context.tt.labelMedium ?? const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      left: width / 2 - fireSize / 2,
                      top: pivotY - radius * 0.42 - fireSize / 2,
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        size: fireSize,
                        color: heat,
                        shadows: [
                          Shadow(color: heat.withValues(alpha: 0.75 * t), blurRadius: 28 * t),
                          Shadow(color: const Color(0xFFFFC46B).withValues(alpha: 0.5 * t), blurRadius: 10 * t),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Space.xs),
          Text('$count', style: context.tt.displaySmall),
          Text(
            count == 1 ? 'day logged this week' : 'days logged this week',
            style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.count,
    required this.radius,
    required this.pivot,
    required this.track,
    required this.label,
    required this.activeLabel,
    required this.labelStyle,
  });

  /// Animated position, 0-7 (may be fractional).
  final double value;

  /// Final count, used to highlight its label.
  final int count;
  final double radius;
  final Offset pivot;
  final Color track;
  final Color label;
  final Color activeLabel;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final t = (value / HeatGauge.maxDays).clamp(0.0, 1.0);
    final heat = HeatGauge.heatColor(value);
    final rect = Rect.fromCircle(center: pivot, radius: radius);
    final stroke = radius * 0.14;

    // Warm glow behind the fire, stronger as the week heats up.
    if (t > 0) {
      final glowCenter = pivot.translate(0, -radius * 0.42);
      final glowRadius = radius * (0.5 + 0.25 * t);
      canvas.drawCircle(
        glowCenter,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [heat.withValues(alpha: 0.35 * t), heat.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
      );
    }

    // Track
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Filled part: the heat scale up to the current value.
    if (value > 0.01) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * t,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: math.pi,
            endAngle: 2 * math.pi,
            colors: [for (var d = 0; d <= HeatGauge.maxDays; d++) HeatGauge.heatColor(d.toDouble())],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks + 0..7 labels, evenly spaced.
    final tick = Paint()
      ..color = label.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var d = 0; d <= HeatGauge.maxDays; d++) {
      final a = HeatGauge.angleFor(d.toDouble());
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(pivot + dir * (radius + stroke / 2 + 3), pivot + dir * (radius + stroke / 2 + 7), tick);

      final isCurrent = d == count;
      final tp = TextPainter(
        text: TextSpan(
          text: '$d',
          style: labelStyle.copyWith(
            color: isCurrent ? activeLabel : label,
            fontSize: (labelStyle.fontSize ?? 12) * (isCurrent ? 1.25 : 1),
            fontWeight: isCurrent ? FontWeight.w800 : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final c = pivot + dir * (radius + stroke / 2 + 18);
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    // Needle: a tapered pointer from just outside the fire to the track.
    final a = HeatGauge.angleFor(value);
    final dir = Offset(math.cos(a), math.sin(a));
    final normal = Offset(-dir.dy, dir.dx);
    final base = pivot + dir * (radius * 0.66);
    final tip = pivot + dir * (radius - stroke * 0.2);
    final halfWidth = radius * 0.05;
    final needle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * halfWidth, base.dy + normal.dy * halfWidth)
      ..lineTo(base.dx - normal.dx * halfWidth, base.dy - normal.dy * halfWidth)
      ..close();
    final needleColor = Color.lerp(activeLabel, heat, 0.55)!;
    canvas.drawPath(needle, Paint()..color = needleColor);
    canvas.drawCircle(base, halfWidth, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.count != count ||
      old.radius != radius ||
      old.pivot != pivot ||
      old.track != track ||
      old.label != label ||
      old.activeLabel != activeLabel;
}
