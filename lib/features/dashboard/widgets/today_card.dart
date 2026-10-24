import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/happiness.dart';
import '../../../core/models/streak.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/journey_card.dart';
import '../../../shared/widgets/otter_mascot.dart';

/// Otter + today's progress toward `n` entries + a streak nudge.
class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.streak, required this.mood});

  final StreakInfo streak;

  /// Average happiness today; null before the first entry.
  final int? mood;

  String get _message {
    if (streak.dailyGoalReached) {
      return 'That\'s all ${streak.entriesPerDay} for today. Nice work.';
    }
    if (!streak.todayCounts) {
      return streak.current > 0
          ? 'Log an entry to keep your ${streak.current}-day streak going.'
          : 'Log your first entry to start a streak.';
    }
    return 'Streak\'s safe for today. Best so far: ${streak.best} days.';
  }

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      child: Row(
        children: [
          OtterMascot(mood: mood ?? Happiness.neutral, size: 84),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${streak.loggedToday}', style: context.tt.headlineSmall),
                      TextSpan(
                        text: ' of ${streak.entriesPerDay} entries today',
                        style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: streak.todayProgress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 12,
                      semanticsLabel: '${streak.loggedToday} of ${streak.entriesPerDay} entries today',
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(_message, style: context.tt.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
