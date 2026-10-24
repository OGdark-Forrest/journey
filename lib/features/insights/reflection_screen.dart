import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../../core/models/insight.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/otter_mascot.dart';
import 'widgets/day_picker.dart';
import 'widgets/insight_page.dart';
import 'widgets/insight_text.dart';
import 'widgets/insight_walkthrough.dart';

/// Looks back at one of the last 7 days (`POST /reflection`). Steps through
/// goal alignment, overall feeling (with the 1-10 score), and what could have
/// been better.
class ReflectionScreen extends StatelessWidget {
  const ReflectionScreen({super.key});

  static const daysBack = 7;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 0; i < daysBack; i++) DateTime(now.year, now.month, now.day - i)];
    return InsightPage(
      kind: InsightKind.reflection,
      title: 'Reflection',
      intro: 'A look back at how a day went.',
      days: days,
      // Mornings are for yesterday; once the day is underway, reflect on today.
      initialDay: now.hour < 12 ? days[1] : days[0],
      actionLabel: (day) => 'Reflect on ${DayPicker.inSentence(day)}',
      loadingMessage: 'Looking back at your day...',
      stepsFor: _steps,
    );
  }

  static List<WalkthroughStep> _steps(BuildContext context, Insight insight) {
    return [
      for (final s in insight.headedSections)
        if (s.matches(Insight.goalAlignment))
          WalkthroughStep(
            title: s.heading,
            icon: Icons.flag_rounded,
            child: SectionContent(icon: Icons.flag_rounded, title: s.heading, child: InsightText(s.lines)),
          )
        else if (s.matches(Insight.overallFeeling))
          WalkthroughStep(
            title: s.heading,
            icon: Icons.favorite_rounded,
            child: SectionContent(
              icon: Icons.favorite_rounded,
              title: s.heading,
              color: context.jc.flame,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (insight.happinessScore case final score?) ...[
                    _Score(score: score),
                    const SizedBox(height: Space.lg),
                  ],
                  InsightText(s.lines),
                ],
              ),
            ),
          )
        else if (s.matches(Insight.couldBeBetter))
          WalkthroughStep(
            title: 'Could be better',
            icon: Icons.lightbulb_rounded,
            child: SectionContent(
              icon: Icons.lightbulb_rounded,
              title: s.heading,
              color: context.cs.secondary,
              child: _Tips(lines: s.lines),
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

/// Score ring (n/10) next to an otter wearing the matching face.
class _Score extends StatelessWidget {
  const _Score({required this.score});
  final int score;

  /// 1-10 -> 1-5 otter expressions.
  int get _mood => ((score + 1) / 2).round().clamp(Happiness.min, Happiness.max);

  @override
  Widget build(BuildContext context) {
    final color = context.jc.flame;
    return Semantics(
      label: 'Happiness score $score out of 10, ${Happiness.label(_mood).toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(color: context.jc.flameTint, borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 10),
                    duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.2),
                    ),
                  ),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$score', style: context.tt.headlineMedium),
                          TextSpan(text: '/10', style: context.tt.labelMedium?.copyWith(color: context.jc.mutedText)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Happiness score', style: context.tt.labelMedium?.copyWith(color: context.jc.mutedText)),
                  Text(Happiness.label(_mood), style: context.tt.titleLarge),
                ],
              ),
            ),
            OtterMascot(mood: _mood, size: 64, animate: false),
          ],
        ),
      ),
    );
  }
}

/// Bullets as numbered tip tiles; any other text stays as plain paragraphs.
class _Tips extends StatelessWidget {
  const _Tips({required this.lines});
  final List<InsightLine> lines;

  @override
  Widget build(BuildContext context) {
    final tips = [for (final l in lines) if (l.bullet) l];
    final rest = [for (final l in lines) if (!l.bullet) l];
    if (tips.isEmpty) return InsightText(lines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rest.isNotEmpty) ...[InsightText(rest), const SizedBox(height: Space.md)],
        for (final (i, tip) in tips.indexed) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: context.jc.secondarySurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: context.cs.secondary,
                  child: Text(
                    '${i + 1}',
                    style: context.tt.labelMedium?.copyWith(color: context.cs.onSecondary),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(child: RichText(text: boldSpans(context, tip.text, context.tt.bodyLarge))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
