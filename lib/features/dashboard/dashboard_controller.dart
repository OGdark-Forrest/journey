import 'package:flutter/foundation.dart';

import '../../core/models/day_info.dart';
import '../../core/models/entry.dart';
import '../../core/models/streak.dart';
import '../../core/models/time_slot.dart';
import '../../core/repositories/repositories.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._journal);

  final JournalRepository _journal;

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

  DayInfo? _today;
  DayInfo? get today => _today;

  List<LogEntry> _entries = const [];
  List<LogEntry> get entries => _entries;

  bool _savingWake = false;
  bool get savingWake => _savingWake;

  bool get hasData => _streak != null && _today != null;

  /// [silent] keeps current content on screen while refreshing.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        _journal.fetchStreak(),
        _journal.fetchDay(today),
        _journal.fetchEntries(from: DateTime(today.year, today.month, today.day - historyDays), to: today),
      ]);
      _streak = results[0] as StreakInfo;
      _today = results[1] as DayInfo;
      _entries = results[2] as List<LogEntry>;
      _error = null;
    } catch (e) {
      _error = 'Couldn\'t load your journal.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setWakeTime(TimeSlot slot) async {
    final day = _today;
    if (day == null) return;
    _savingWake = true;
    notifyListeners();
    try {
      _today = await _journal.saveWakeTime(
        day.date,
        FieldValue(value: slot, keptDefault: slot == day.wakeTimeDefault),
      );
    } finally {
      _savingWake = false;
      notifyListeners();
    }
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

  /// Average happiness logged today, for the otter on the today card.
  int? get todayMood {
    final day = _today?.date;
    if (day == null) return null;
    final today = _entries.where((e) => e.date == day).map((e) => e.happiness).toList();
    if (today.isEmpty) return null;
    return (today.reduce((a, b) => a + b) / today.length).round();
  }
}
