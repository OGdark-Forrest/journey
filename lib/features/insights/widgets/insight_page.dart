import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../../core/models/happiness.dart';
import '../../../core/models/insight.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/chunky_button.dart';
import '../../../shared/widgets/journey_card.dart';
import '../../../shared/widgets/otter_mascot.dart';
import '../../../shared/widgets/state_views.dart';
import '../insight_controller.dart';
import 'day_picker.dart';
import 'insight_text.dart';
import 'insight_walkthrough.dart';

/// Shared layout for the Reflection and Recommendations pages: a day picker,
/// a "generate" prompt, then the answer as a step-by-step walkthrough that
/// can be switched to a full view.
class InsightPage extends StatefulWidget {
  const InsightPage({
    super.key,
    required this.kind,
    required this.title,
    required this.intro,
    required this.days,
    required this.initialDay,
    required this.actionLabel,
    required this.loadingMessage,
    required this.stepsFor,
  });

  final InsightKind kind;
  final String title;

  /// One line under the app bar explaining the page.
  final String intro;
  final List<DateTime> days;
  final DateTime initialDay;

  /// Generate button label for a day, e.g. "Reflect on today".
  final String Function(DateTime day) actionLabel;
  final String loadingMessage;

  /// One step per section of the answer, in display order.
  final List<WalkthroughStep> Function(BuildContext context, Insight insight) stepsFor;

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  late final AppDependencies _deps = AppScope.of(context);
  late final InsightController _c = InsightController(
    kind: widget.kind,
    repository: _deps.insights,
    days: widget.days,
    initialDay: widget.initialDay,
    cache: _deps.session.insights,
  );

  /// Showing every section at once instead of the walkthrough.
  bool _showAll = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _selectDay(DateTime day) {
    setState(() => _showAll = false);
    _c.selectDay(day);
  }

  void _generate() {
    setState(() => _showAll = false);
    _c.generate();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final insight = _c.insight;
        final ready = insight != null && !insight.isEmpty && !_c.loading;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(widget.title),
            actions: [
              if (ready)
                IconButton(
                  tooltip: _showAll ? 'Step through' : 'Show everything',
                  icon: Icon(_showAll ? Icons.view_carousel_rounded : Icons.view_agenda_rounded),
                  onPressed: () => setState(() => _showAll = !_showAll),
                ),
              if (ready)
                IconButton(tooltip: 'Write a new one', icon: const Icon(Icons.refresh_rounded), onPressed: _generate),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
                  child: Text(widget.intro, style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText)),
                ),
                DayPicker(
                  days: _c.days,
                  selected: _c.day,
                  onSelected: _selectDay,
                  hasInsight: _c.hasInsight,
                ),
                const SizedBox(height: Space.lg),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      // New day / new answer / view switch -> fresh subtree
                      // (the walkthrough restarts at step 1).
                      key: ValueKey((_c.day, _c.loading, insight, _showAll)),
                      child: _body(context, insight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, Insight? insight) {
    if (_c.loading) return _Loading(message: widget.loadingMessage);
    if (insight == null) {
      if (_c.error != null) return ErrorView(message: _c.error!, onRetry: _generate);
      return _Prompt(label: widget.actionLabel(_c.day), onPressed: _generate, kind: widget.kind);
    }
    if (insight.isEmpty) return _Empty(insight: insight, onRetry: _generate);

    final steps = [
      if (insight.intro case final intro?)
        WalkthroughStep(
          title: 'A quick note',
          icon: Icons.info_outline_rounded,
          child: SectionContent(
            icon: Icons.info_outline_rounded,
            title: 'A quick note',
            child: InsightText(intro.lines),
          ),
        ),
      ...widget.stepsFor(context, insight),
    ];

    final meta = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      child: _Meta(insight: insight),
    );

    if (_showAll) {
      return ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          meta,
          const SizedBox(height: Space.md),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.lg),
              child: JourneyCard(child: s.child),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: ChunkyButton(
              label: 'Step through again',
              icon: Icons.view_carousel_rounded,
              variant: ChunkyVariant.secondary,
              onPressed: () => setState(() => _showAll = false),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        meta,
        const SizedBox(height: Space.sm),
        Expanded(
          child: InsightWalkthrough(steps: steps, onFinished: () => setState(() => _showAll = true)),
        ),
      ],
    );
  }
}

/// "Based on 5 entries · Written 3:42 PM"
class _Meta extends StatelessWidget {
  const _Meta({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final n = insight.entryCount;
    final written = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(insight.generatedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.xs,
      children: [
        TagPill(label: 'Based on $n ${n == 1 ? 'entry' : 'entries'}', icon: Icons.edit_note_rounded),
        TagPill(label: 'Written $written', icon: Icons.auto_awesome_rounded),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.label, required this.onPressed, required this.kind});

  final String label;
  final VoidCallback onPressed;
  final InsightKind kind;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (kind) {
      InsightKind.reflection => (
          'Ready when you are',
          'We\'ll read that day\'s entries next to your goals and write you a short reflection: '
              'how it lined up, how it felt, and what could go better.',
        ),
      InsightKind.recommendations => (
          'Let\'s plan your day',
          'We\'ll look at your habits on this weekday, how recent days felt, and your goals, '
              'then suggest a simple morning, afternoon and evening.',
        ),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.xxl),
      child: Column(
        children: [
          const OtterMascot(mood: Happiness.max - 1, size: 120),
          const SizedBox(height: Space.lg),
          Text(title, style: context.tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(
            body,
            style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          ChunkyButton(label: label, icon: Icons.auto_awesome_rounded, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OtterMascot(mood: Happiness.neutral, size: 110),
            const SizedBox(height: Space.lg),
            Text(message, style: context.tt.titleMedium),
            const SizedBox(height: Space.md),
            const SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 6)),
          ],
        ),
      ),
    );
  }
}

/// The service answered without any sections (e.g. nothing logged that day).
class _Empty extends StatelessWidget {
  const _Empty({required this.insight, required this.onRetry});
  final Insight insight;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.xxl),
      child: Column(
        children: [
          const OtterMascot(mood: Happiness.min + 1, size: 110),
          const SizedBox(height: Space.lg),
          Text(Insight.stripBold(insight.text.trim()), style: context.tt.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(
            'Log a few moments that day, or pick another day above.',
            style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          ChunkyButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            variant: ChunkyVariant.secondary,
            expand: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
