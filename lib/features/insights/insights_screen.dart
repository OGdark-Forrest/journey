import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/otter_mascot.dart';

/// Suggestions / reflections / insights.
///
/// TODO(post-mvp): LLM-generated content on request (happiness / wellness
/// score, reflections, suggestions). Needs a new endpoint in
/// .kiro/steering/api-contract.md, e.g. `POST /insights`.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _planned = [
    (Icons.favorite_rounded, 'Wellness score', 'A gentle read on how your days have been going.'),
    (Icons.lightbulb_rounded, 'Suggestions', 'Small ideas based on what tends to lift your mood.'),
    (Icons.menu_book_rounded, 'Reflections', 'A short look back at your week, written for you.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.xxl),
        children: [
          const Center(child: OtterMascot(mood: Happiness.max - 1, size: 120)),
          const SizedBox(height: Space.lg),
          Text('Insights are on the way', style: context.tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(
            'Once you\'ve logged a while, you\'ll be able to ask for these whenever you like.',
            style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          for (final (icon, title, body) in _planned) ...[
            JourneyCard(
              child: Row(
                children: [
                  Icon(icon, color: context.cs.primary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.tt.titleMedium),
                        Text(body, style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          const SizedBox(height: Space.lg),
          const ChunkyButton(label: 'Generate insights', icon: Icons.auto_awesome_rounded, onPressed: null),
        ],
      ),
    );
  }
}
