import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/models/entry.dart';
import '../../core/models/goal.dart';
import '../../shared/theme/palette.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/streak_pill.dart';
import '../log_entry/log_entry_controller.dart';
import 'dashboard_controller.dart';
import 'widgets/goals_card.dart';
import 'widgets/greeting_box.dart';
import 'widgets/history_list.dart';
import 'widgets/log_card.dart';
import 'widgets/premium_banner.dart';

/// Home: Premium banner, greeting + streak, log card, insights, and a
/// scrollable log history that can expand to full screen.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  /// Size multiplier for the streak and settings buttons.
  static const _buttonScale = 1.4;
  static const _minHistoryHeight = 200.0;

  late final AppDependencies _deps = AppScope.of(context);
  late final DashboardController _c = DashboardController(_deps.journal, _deps.premium, _deps.goals);

  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  final _stackKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final _historyScroll = ScrollController();

  /// Expanded view is mounted (stays true until the collapse animation ends).
  bool _expanded = false;

  /// History viewport bounds (in the stack's coordinates) the animation grows from.
  Rect? _fromRect;

  /// Blocks double taps from pushing the same screen twice.
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _expand.dispose();
    _historyScroll.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  // ---- Navigation ------------------------------------------------------------

  Future<T?> _push<T>(String location) async {
    if (_navigating) return null;
    _navigating = true;
    try {
      return await context.push<T>(location);
    } finally {
      _navigating = false;
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
  }

  Future<void> _logEvent() async {
    if (_navigating) return;
    final result = await _push<SaveEntryResult>(Routes.logEntry);
    if (!mounted || result == null) return;
    final ok = await _c.load(silent: true);
    if (!mounted) return;
    if (!ok) {
      _snack('Entry saved, but the dashboard couldn\'t refresh.');
      return;
    }
    if (shouldCelebrate(result)) return; // already celebrated
    _snack('Entry saved.');
  }

  Future<void> _openSettings() async {
    if (_navigating) return;
    await _push<void>(Routes.settings);
    if (mounted) _c.load(silent: true); // prefs may have changed
  }

  Future<void> _openStreak() => _push<void>(Routes.weeklyStreak);

  Future<void> _addGoal(GoalPeriod period, String text) async {
    try {
      await _c.addGoal(period, text);
    } catch (_) {
      _snack('Couldn\'t save that goal.');
    }
  }

  Future<void> _refresh() async {
    final ok = await _c.load(silent: true);
    if (!ok && mounted) _snack('Couldn\'t refresh your journal.');
  }

  void _dismissBanner() => setState(() => _deps.session.premiumBannerDismissed = true);

  // ---- Expand / collapse -----------------------------------------------------

  Rect? _viewportRect() {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
  }

  void _openExpanded() {
    if (_expanded || _expand.isAnimating) return;
    setState(() {
      _fromRect = _viewportRect();
      _expanded = true;
    });
    if (_reduceMotion) {
      _expand.value = 1;
    } else {
      _expand.forward(from: 0);
    }
  }

  void _closeExpanded() {
    if (!_expanded || _expand.isAnimating) return;
    _fromRect = _viewportRect() ?? _fromRect;
    if (_reduceMotion) {
      _expand.value = 0;
      setState(() => _expanded = false);
      return;
    }
    _expand.reverse().whenComplete(() {
      if (mounted) setState(() => _expanded = false);
    });
  }

  // ---- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_expanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeExpanded();
      },
      child: Scaffold(
        backgroundColor: Palette.dashboardBlue,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([_c, _deps.app]),
            builder: (context, _) {
              if (_c.loading && !_c.hasData) return const LoadingView();
              if (!_c.hasData) {
                return ErrorView(message: _c.error ?? 'Something went wrong.', onRetry: _c.load);
              }
              return Stack(
                key: _stackKey,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _expanded,
                      child: ExcludeSemantics(excluding: _expanded, child: _content(context)),
                    ),
                  ),
                  if (_expanded) Positioned.fill(child: _expandedOverlay(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final streak = _c.streak!;
    final groups = _c.groupedEntries;
    final showBanner = _c.isPremium == false && !_deps.session.premiumBannerDismissed;
    const settingsSize = 48 * _buttonScale;

    return RefreshIndicator(
      onRefresh: _refresh,
      // Also refresh when pulling down inside the history list (depth 1).
      notificationPredicate: (n) => n.depth <= 1,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: showBanner
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: Space.md),
                            child: PremiumBanner(
                              onOpenInsights: () => _push<void>(Routes.insights),
                              onDismiss: _dismissBanner,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GreetingBox(
                          name: _deps.app.prefs?.displayName ?? '',
                          otterMood: _deps.launchMood.mood,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      StreakPill(
                        days: streak.current,
                        activeToday: streak.todayCounts,
                        scale: _buttonScale,
                        onTap: _openStreak,
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        iconSize: 24 * _buttonScale,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: settingsSize, height: settingsSize),
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  LogCard(onLogEvent: _logEvent),
                  const SizedBox(height: Space.xl),
                  const _InsightsTeaser(),
                  const SizedBox(height: Space.lg),
                  GoalsCard(
                    goalsFor: _c.goalsFor,
                    onAdd: _addGoal,
                    onComplete: _c.completeGoal,
                  ),
                  const SizedBox(height: Space.lg),
                  _HistoryHeader(
                    icon: Icons.open_in_full_rounded,
                    tooltip: 'Expand log history',
                    onPressed: _openExpanded,
                  ),
                  const SizedBox(height: Space.xs),
                ],
              ),
            ),
          ),
          // History viewport fills the rest of the screen (min 200px). Its own
          // scroll doesn't move the dashboard.
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final remaining = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
              return SliverToBoxAdapter(
                child: SizedBox(
                  key: _viewportKey,
                  height: math.max(_minHistoryHeight, remaining),
                  child: HistoryList(
                    groups: groups,
                    controller: _historyScroll,
                    padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _expandedOverlay(BuildContext context) {
    final groups = _c.groupedEntries;
    const background = Palette.dashboardBlue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = Offset.zero & constraints.biggest;
        return AnimatedBuilder(
          animation: _expand,
          builder: (context, child) {
            final t = Curves.easeInOutCubic.transform(_expand.value);
            final rect = Rect.lerp(_fromRect ?? full, full, t)!;
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: Material(
                    color: background,
                    elevation: 6 * (1 - t),
                    borderRadius: BorderRadius.circular(lerpDouble(Radii.lg, 0, t)!),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.xs),
                child: _HistoryHeader(
                  icon: Icons.close_fullscreen_rounded,
                  tooltip: 'Collapse log history',
                  onPressed: _closeExpanded,
                ),
              ),
              Expanded(
                child: HistoryList(
                  groups: groups,
                  padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Log History" title with the expand / collapse button next to it.
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text('Log History', style: context.tt.titleLarge)),
        ),
        IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
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
