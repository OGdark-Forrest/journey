import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/repositories/repositories.dart';
import 'week_math.dart';

/// Loads this Monday-to-Sunday week's entries and works out which days were
/// logged. The week is recomputed on every load, so it resets each Monday.
class WeeklyStreakController extends ChangeNotifier {
  WeeklyStreakController(this._journal, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final JournalRepository _journal;
  final DateTime Function() _clock;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<DateTime> _week = const [];

  /// Mon..Sun of the current local week.
  List<DateTime> get week => _week;

  DateTime? _today;
  DateTime? get today => _today;

  Set<DateTime>? _logged;

  /// Days of [week] with at least one entry. Null until loaded.
  Set<DateTime>? get logged => _logged;

  /// 0-7. Null until loaded.
  int? get count => _logged?.length;

  bool _disposed = false;

  /// [silent] keeps the current week on screen while refreshing.
  Future<bool> load({bool silent = false}) async {
    if (!silent || _logged == null) {
      _loading = true;
      _error = null;
      _notify();
    }
    final now = _clock();
    final week = weekOf(now);
    try {
      final entries = await _journal
          .fetchEntries(from: week.first, to: week.last)
          .timeout(const Duration(seconds: 10));
      _week = week;
      _today = dateOnly(now);
      _logged = loggedDaysIn(week, entries);
      _error = null;
      return true;
    } catch (e) {
      debugPrint('Weekly streak load failed: $e');
      if (!silent) _logged = null;
      _error = 'Couldn\'t load your weekly progress.';
      return false;
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
