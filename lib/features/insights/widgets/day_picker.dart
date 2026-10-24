import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';

/// Horizontal row of day chips ("Today", "Yesterday", "Wed 22"...).
/// Days with a generated insight get a small check.
class DayPicker extends StatelessWidget {
  const DayPicker({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
    this.hasInsight,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime day)? hasInsight;

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static int _offset(DateTime day) {
    final now = DateTime.now();
    return DateTime(day.year, day.month, day.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// "Today" / "Tomorrow" / "Yesterday", otherwise the short weekday ("Wed").
  static String relativeLabel(DateTime day) => switch (_offset(day)) {
        0 => 'Today',
        1 => 'Tomorrow',
        -1 => 'Yesterday',
        _ => _weekdays[day.weekday - 1].substring(0, 3),
      };

  /// For sentences: "today" / "tomorrow" / "yesterday" / "Wednesday".
  static String inSentence(DateTime day) => switch (_offset(day)) {
        0 || 1 || -1 => relativeLabel(day).toLowerCase(),
        _ => _weekdays[day.weekday - 1],
      };

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day == selected;
          final done = hasInsight?.call(day) ?? false;
          final fg = isSelected ? context.cs.onPrimary : context.cs.onSurface;
          return Semantics(
            selected: isSelected,
            button: true,
            label: '${relativeLabel(day)}, ${loc.formatMediumDate(day)}${done ? ', ready' : ''}',
            excludeSemantics: true,
            child: Material(
              color: isSelected ? context.cs.primary : context.cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                side: BorderSide(color: isSelected ? context.jc.primaryEdge : context.jc.cardBorder, width: 2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () => onSelected(day),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(relativeLabel(day), style: context.tt.labelMedium?.copyWith(color: fg)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${day.day}', style: context.tt.titleMedium?.copyWith(color: fg)),
                            if (done) ...[
                              const SizedBox(width: Space.xs),
                              Icon(Icons.check_circle_rounded, size: 14, color: isSelected ? fg : context.cs.primary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
