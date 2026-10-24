import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/otter_mascot.dart';
import 'widgets/insight_text.dart';

/// Hub for the LLM-backed pages: Reflection (look back at a day) and
/// Recommendations (plan a day). Each is generated on request.
// TODO(post-mvp): gate behind Premium once the paywall exists.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.xxl),
        children: [
          const Center(child: OtterMascot(mood: Happiness.max - 1, size: 120)),
          const SizedBox(height: Space.lg),
          Text('What would you like?', style: context.tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(
            'Both are written from your own entries and goals, whenever you ask.',
            style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          _Choice(
            icon: Icons.menu_book_rounded,
            title: 'Reflection',
            body: 'Look back at a day: how it matched your goals, how it felt, and what could go better.',
            onTap: () => context.push(Routes.reflection),
          ),
          const SizedBox(height: Space.md),
          _Choice(
            icon: Icons.lightbulb_rounded,
            color: context.jc.flame,
            title: 'Recommendations',
            body: 'Plan a day ahead: a simple morning, afternoon and evening, plus what to focus on.',
            onTap: () => context.push(Routes.recommendations),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.body, required this.onTap, this.color});

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      onTap: onTap,
      semanticLabel: '$title. $body',
      child: ExcludeSemantics(
        child: Row(
          children: [
            SectionBadge(icon: icon, color: color),
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
            Icon(Icons.chevron_right_rounded, color: context.jc.mutedText),
          ],
        ),
      ),
    );
  }
}
