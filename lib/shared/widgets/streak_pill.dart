import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../theme/spacing.dart';

/// Flame + day count. Dimmed until today counts toward the streak.
///
/// [scale] multiplies the icon, text, padding, and gap. Pass [onTap] to make
/// it a button (dashboard opens the weekly streak page).
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days, required this.activeToday, this.scale = 1.0, this.onTap});

  final int days;
  final bool activeToday;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final color = activeToday ? jc.flame : jc.mutedText;
    final base = context.tt.titleMedium;
    final radius = BorderRadius.circular(Radii.pill);
    final status = '$days day streak${activeToday ? '' : ', not logged today yet'}';

    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: Space.md * scale, vertical: (Space.xs + 2) * scale),
      decoration: BoxDecoration(
        color: activeToday ? jc.flameTint : jc.secondarySurface,
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: color, size: 22 * scale),
          SizedBox(width: 2 * scale),
          Text(
            '$days',
            style: base?.copyWith(color: color, fontSize: (base.fontSize ?? 16) * scale),
          ),
        ],
      ),
    );

    if (onTap != null) {
      pill = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, borderRadius: radius, child: Center(widthFactor: 1, child: pill)),
        ),
      );
    }

    return Semantics(
      label: onTap == null ? status : '$status. Opens your weekly streak.',
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: pill,
    );
  }
}
