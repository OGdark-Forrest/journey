import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/state_views.dart';
import 'weekly_streak_controller.dart';
import 'widgets/heat_gauge.dart';
import 'widgets/resting_otter.dart';

/// Opened from the dashboard streak button: Mon-Sun tick boxes on top, a heat
/// gauge below, and a resting otter at the bottom. Resets every Monday.
class WeeklyStreakScreen extends StatefulWidget {
  const WeeklyStreakScreen({super.key});

  @override
  State<WeeklyStreakScreen> createState() => _WeeklyStreakScreenState();
}

class _WeeklyStreakScreenState extends State<WeeklyStreakScreen> {
  late final WeeklyStreakController _c = WeeklyStreakController(AppScope.of(context).journal);

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

  Future<void> _refresh() async {
    final ok = await _c.load(silent: true);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t refresh your week.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to dashboard',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('This week'),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final logged = _c.logged;
            if (_c.loading && logged == null) return const LoadingView();
            if (logged == null) {
              return ErrorView(message: _c.error ?? 'Something went wrong.', onRetry: _c.load);
            }
            return RefreshIndicator(onRefresh: _refresh, child: _content(context, logged));
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Set<DateTime> logged) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - Space.screen * 2;
        final gaugeWidth = math.min(contentWidth, 320.0);
        final otterWidth = math.min(contentWidth * 0.7, 240.0);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.lg),
          child: ConstrainedBox(
            // Fill the screen so the gauge sits low and the otter at the bottom;
            // scrolls instead on short screens.
            constraints: BoxConstraints(minHeight: constraints.maxHeight - Space.md - Space.lg),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WeekRow(week: _c.week, logged: logged, today: _c.today!),
                  const SizedBox(height: Space.xl),
                  const Spacer(),
                  Center(child: HeatGauge(count: logged.length, width: gaugeWidth)),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Resets every Monday',
                    textAlign: TextAlign.center,
                    style: context.tt.bodySmall?.copyWith(color: context.jc.mutedText),
                  ),
                  const SizedBox(height: Space.xl),
                  const Spacer(),
                  Center(child: RestingOtter(width: otterWidth)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mon..Sun labels with a box under each; logged days get a tick.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.logged, required this.today});

  final List<DateTime> week;
  final Set<DateTime> logged;
  final DateTime today;

  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _full = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final cs = context.cs;
    return Row(
      children: [
        for (final (i, day) in week.indexed)
          Expanded(
            child: Builder(
              builder: (context) {
                final isLogged = logged.contains(day);
                final isToday = day == today;
                return Semantics(
                  label: '${_full[i]}, ${isLogged ? 'logged' : 'not logged'}${isToday ? ', today' : ''}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        _short[i],
                        maxLines: 1,
                        softWrap: false,
                        style: context.tt.labelMedium?.copyWith(
                          color: isToday ? jc.flame : jc.mutedText,
                          fontWeight: isToday ? FontWeight.w800 : null,
                        ),
                      ),
                      const SizedBox(height: Space.xs + 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isLogged ? cs.primary : cs.surface,
                                borderRadius: BorderRadius.circular(Radii.sm - 2),
                                border: Border.all(
                                  color: isToday ? jc.flame : (isLogged ? cs.primary : jc.cardBorder),
                                  width: isToday ? 3 : 2,
                                ),
                              ),
                              child: isLogged
                                  ? FittedBox(
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(Icons.check_rounded, color: cs.onPrimary),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
