import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/entry.dart';
import '../../core/models/goal.dart';
import '../../core/models/streak.dart';
import '../../core/repositories/repositories.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._journal, this._premium, this._goalRepo);

  final JournalRepository _journal;
  final PremiumRepository _premium;
  final GoalRepository _goalRepo;

  /// How far back the history list goes.
  // TODO(backend): replace with paging over `GET /entries?from=&to=` (load
  // older days as the user scrolls).
  static const historyDays = 14;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreakInfo? _streak;
  StreakInfo? get streak => _streak;

  List<LogEntry> _entries = const [];
  List<LogEntry> get entries => _entries;

  /// Null = unknown (still loading, or the check failed). The Premium banner
  /// only shows when this is explicitly false.
  bool? _isPremium;
  bool? get isPremium => _isPremium;

  List<Goal> _goals = const [];

  /// Goals of [period], in the order they were added.
  List<Goal> goalsFor(GoalPeriod period) => [for (final g in _goals) if (g.period == period) g];

  bool get hasData => _streak != null;

  /// [silent] keeps current content on screen while refreshing.
  /// Returns false if the journal couldn't be loaded.
  Future<bool> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    unawaited(_loadPremium());
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        _journal.fetchStreak(),
        _journal.fetchEntries(from: DateTime(today.year, today.month, today.day - historyDays), to: today),
        _goalRepo.fetch(),
      ]);
      _streak = results[0] as StreakInfo;
      _entries = results[1] as List<LogEntry>;
      _goals = results[2] as List<Goal>;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Couldn\'t load your journal.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Throws if the goal couldn't be saved. The list is left unchanged.
  Future<void> addGoal(GoalPeriod period, String text) async {
    final goal = await _goalRepo.add(period, text);
    _goals = [..._goals, goal];
    notifyListeners();
  }

  /// Checking a goal off deletes it. It disappears at once and comes back if
  /// the delete fails.
  Future<void> completeGoal(Goal goal) async {
    final before = _goals;
    _goals = [for (final g in _goals) if (g.id != goal.id) g];
    notifyListeners();
    try {
      await _goalRepo.delete(goal.id);
    } catch (e) {
      debugPrint('Could not delete goal: $e');
      _goals = before;
      notifyListeners();
    }
  }

  /// Failures are silent: the banner just stays hidden.
  Future<void> _loadPremium() async {
    try {
      _isPremium = await _premium.isPremium().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Premium status unavailable: $e');
      _isPremium = null;
    }
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Entries grouped by day, newest day first.
  List<(DateTime, List<LogEntry>)> get groupedEntries {
    final groups = <DateTime, List<LogEntry>>{};
    for (final e in _entries) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final d in days) (d, groups[d]!)];
  }
}
