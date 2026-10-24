import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/models/entry.dart';
import '../../core/models/happiness.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/otter_mascot.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/streak_pill.dart';
import '../../shared/widgets/time_format.dart';
import '../log_entry/log_entry_controller.dart';
import 'dashboard_controller.dart';
import 'widgets/history_tile.dart';
import 'widgets/today_card.dart';
import 'widgets/wake_up_card.dart';

/// Home: streak, today's progress, wake-up time, log buttons, and history.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AppDependencies _deps = AppScope.of(context);
  late final DashboardController _c = DashboardController(_deps.journal);

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _log(EntryMode mode) async {
    final result = await context.push<SaveEntryResult>(Routes.logEntryFor(mode));
    if (!mounted || result == null) return;
    await _c.load(silent: true);
    if (!mounted || shouldCelebrate(result)) return; // already celebrated
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved. ${result.indexToday} of ${result.streak.entriesPerDay} today.')),
    );
  }

  Future<void> _openSettings() async {
    await context.push(Routes.settings);
    if (mounted) _c.load(silent: true); // entries-per-day may have changed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_c, _deps.app]),
          builder: (context, _) {
            if (_c.loading && !_c.hasData) return const LoadingView();
            if (!_c.hasData) {
              return ErrorView(message: _c.error ?? 'Something went wrong.', onRetry: _c.load);
            }
            return RefreshIndicator(
              onRefresh: () => _c.load(silent: true),
              child: _content(context),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final streak = _c.streak!;
    final name = _deps.app.prefs?.displayName ?? '';
    final groups = _c.groupedEntries;
    const gap = SliverToBoxAdapter(child: SizedBox(height: Space.lg));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.sm, Space.lg),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${greetingFor(DateTime.now())}${name.isEmpty ? '' : ', $name'}',
                    style: context.tt.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StreakPill(days: streak.current, activeToday: streak.todayCounts),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          sliver: SliverList.list(
            children: [
              TodayCard(streak: streak, mood: _c.todayMood),
              const SizedBox(height: Space.lg),
              WakeUpCard(day: _c.today!, saving: _c.savingWake, onSave: _c.setWakeTime),
              const SizedBox(height: Space.xl),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ChunkyButton(
                      label: 'Log an event',
                      icon: Icons.add_rounded,
                      onPressed: streak.dailyGoalReached ? null : () => _log(EntryMode.normal),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    flex: 2,
                    child: ChunkyButton(
                      label: 'Blitz',
                      icon: Icons.bolt_rounded,
                      variant: ChunkyVariant.flame,
                      onPressed: streak.dailyGoalReached ? null : () => _log(EntryMode.blitz),
                    ),
                  ),
                ],
              ),
              if (streak.dailyGoalReached) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'You\'ve hit today\'s ${streak.entriesPerDay} entries. You can change this in Settings.',
                  style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
                ),
              ],
              const SizedBox(height: Space.xl),
              const _InsightsTeaser(),
              const SizedBox(height: Space.xl),
              Text('Your log', style: context.tt.titleLarge),
            ],
          ),
        ),
        if (groups.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.all(Space.screen),
            sliver: SliverToBoxAdapter(child: _EmptyHistory()),
          ),
        for (final (day, entries) in groups) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.sm),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Text(
                  formatDayHeader(context, day),
                  style: context.tt.titleSmall?.copyWith(color: context.jc.mutedText),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            sliver: SliverList.separated(
              itemCount: entries.length,
              itemBuilder: (_, i) => HistoryTile(entry: entries[i]),
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            ),
          ),
        ],
        gap,
        gap,
      ],
    );
  }
}

/// Post-MVP placeholder entry point for LLM insights.
class _InsightsTeaser extends StatelessWidget {
  const _InsightsTeaser();

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      onTap: () => context.push(Routes.insights),
      semanticLabel: 'Insights, coming soon',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: context.jc.flame),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insights', style: context.tt.titleMedium),
                  Text(
                    'Reflections and a wellness score',
                    style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
                  ),
                ],
              ),
            ),
            const TagPill(label: 'soon', icon: Icons.lock_clock_rounded),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OtterMascot(mood: Happiness.neutral, size: 72, animate: false),
        const SizedBox(height: Space.md),
        Text(
          'No entries yet. Your first one takes about 10 seconds.',
          textAlign: TextAlign.center,
          style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
        ),
      ],
    );
  }
}
