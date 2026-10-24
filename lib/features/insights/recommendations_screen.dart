import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/insight.dart';
import '../../shared/theme/spacing.dart';
import 'widgets/day_picker.dart';
import 'widgets/insight_page.dart';
import 'widgets/insight_text.dart';
import 'widgets/insight_walkthrough.dart';

/// Plans today or one of the next few days (`POST /recommendations`). Steps
/// through the day plan (morning / afternoon / evening) and the goal focus
/// (push, balanced, or rest day).
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  static const daysAhead = 4;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 0; i < daysAhead; i++) DateTime(now.year, now.month, now.day + i)];
    return InsightPage(
      kind: InsightKind.recommendations,
      title: 'Recommendations',
      intro: 'A realistic plan built from your habits and goals.',
      days: days,
      // By the evening, today is mostly done, so plan tomorrow.
      initialDay: now.hour >= 17 ? days[1] : days[0],
      actionLabel: (day) => 'Plan ${DayPicker.inSentence(day)}',
      loadingMessage: 'Putting a plan together...',
      stepsFor: _steps,
    );
  }

  static List<WalkthroughStep> _steps(BuildContext context, Insight insight) {
    return [
      for (final s in insight.headedSections)
        if (s.matches(Insight.dayPlan))
          WalkthroughStep(
            title: s.heading,
            icon: Icons.schedule_rounded,
            child: SectionContent(
              icon: Icons.schedule_rounded,
              title: s.heading,
              child: _Plan(plan: insight.plan, fallback: s.lines),
            ),
          )
        else if (s.matches(Insight.goalFocus))
          WalkthroughStep(
            title: s.heading,
            icon: Icons.track_changes_rounded,
            child: SectionContent(
              icon: Icons.track_changes_rounded,
              title: s.heading,
              color: context.jc.flame,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (insight.dayType case final type?) ...[
                    _DayTypeBanner(type: type),
                    const SizedBox(height: Space.lg),
                  ],
                  InsightText(s.lines),
                ],
              ),
            ),
          )
        else
          WalkthroughStep(
            title: s.heading,
            icon: Icons.notes_rounded,
            child: SectionContent(icon: Icons.notes_rounded, title: s.heading, child: InsightText(s.lines)),
          ),
    ];
  }
}

/// Morning / afternoon / evening as a small vertical timeline. Falls back to
/// the raw text if the model didn't label the parts of the day.
class _Plan extends StatelessWidget {
  const _Plan({required this.plan, required this.fallback});

  final Map<DayPart, List<String>> plan;
  final List<InsightLine> fallback;

  static IconData _icon(DayPart p) => switch (p) {
        DayPart.morning => Icons.wb_twilight_rounded,
        DayPart.afternoon => Icons.wb_sunny_rounded,
        DayPart.evening => Icons.nights_stay_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final parts = [for (final p in DayPart.values) if (plan[p]!.isNotEmpty) p];
    if (parts.isEmpty) return InsightText(fallback);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, part) in parts.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dot + connecting line.
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: context.jc.selectedTint, shape: BoxShape.circle),
                        child: Icon(_icon(part), size: 20, color: context.cs.primary),
                      ),
                      if (i < parts.length - 1)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: Space.xs),
                            decoration: BoxDecoration(
                              color: context.jc.secondarySurface,
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 6, bottom: i < parts.length - 1 ? Space.lg : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(part.label, style: context.tt.titleMedium)),
                        const SizedBox(height: Space.xs),
                        InsightText([for (final item in plan[part]!) InsightLine(item, bullet: true)]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayTypeBanner extends StatelessWidget {
  const _DayTypeBanner({required this.type});
  final DayType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color, hint) = switch (type) {
      DayType.push => (Icons.bolt_rounded, context.jc.flame, 'Good energy for progress'),
      DayType.balanced => (Icons.balance_rounded, context.cs.primary, 'A bit of progress, a bit of routine'),
      DayType.rest => (Icons.spa_rounded, context.cs.secondary, 'Go easy and recharge'),
    };
    return Semantics(
      label: '${type.label}. $hint',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label, style: context.tt.titleLarge),
                  Text(hint, style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
