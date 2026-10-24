import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../theme/spacing.dart';

/// Flame + day count. Dimmed until today counts toward the streak.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days, required this.activeToday});

  final int days;
  final bool activeToday;

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final color = activeToday ? jc.flame : jc.mutedText;
    return Semantics(
      label: '$days day streak${activeToday ? '' : ', not logged today yet'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs + 2),
        decoration: BoxDecoration(
          color: activeToday ? jc.flameTint : jc.secondarySurface,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, color: color, size: 22),
            const SizedBox(width: 2),
            Text('$days', style: context.tt.titleMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
