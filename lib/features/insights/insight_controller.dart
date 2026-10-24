import 'package:flutter/foundation.dart';

import '../../core/models/insight.dart';
import '../../core/repositories/repositories.dart';

/// State for one insights page: which day is picked, and the generated
/// reflection / plan for each day. Insights are only generated when the user
/// asks (each one is a model call), then cached in [cache] for the session.
class InsightController extends ChangeNotifier {
  InsightController({
    required this.kind,
    required InsightsRepository repository,
    required this.days,
    required DateTime initialDay,
    required this._cache,
  })  : _repo = repository,
        _day = initialDay;

  final InsightKind kind;

  /// Days the user can pick from, in display order.
  final List<DateTime> days;

  final InsightsRepository _repo;
  final Map<(InsightKind, DateTime), Insight> _cache;

  DateTime _day;
  DateTime get day => _day;

  final Set<DateTime> _loading = {};
  bool get loading => _loading.contains(_day);

  final Map<DateTime, String> _errors = {};
  String? get error => _errors[_day];

  Insight? get insight => _cache[(kind, _day)];

  bool hasInsight(DateTime day) => _cache.containsKey((kind, day));

  bool _disposed = false;

  void selectDay(DateTime day) {
    if (day == _day) return;
    _day = day;
    _notify();
  }

  /// Generates the insight for the selected day. A request still running for
  /// another day keeps going and fills that day's cache when it lands.
  Future<void> generate() async {
    final day = _day;
    if (_loading.contains(day)) return;
    _loading.add(day);
    _errors.remove(day);
    _notify();
    try {
      final result = await switch (kind) {
        InsightKind.reflection => _repo.reflect(day),
        InsightKind.recommendations => _repo.recommend(day),
      }
          .timeout(const Duration(seconds: 60));
      _cache[(kind, day)] = result;
    } catch (e) {
      debugPrint('Insight ($kind) failed: $e');
      _errors[day] = kind == InsightKind.reflection
          ? 'Couldn\'t write your reflection. Check your connection and try again.'
          : 'Couldn\'t put a plan together. Check your connection and try again.';
    } finally {
      _loading.remove(day);
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
