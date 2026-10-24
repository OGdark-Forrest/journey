import '../models/assessment.dart';
import '../models/entry.dart';
import '../models/goal.dart';
import '../models/happiness.dart';
import '../models/insight.dart';
import 'repositories.dart';

/// Body for `POST /reflection` and `POST /recommendations`. Mirrors
/// `InsightRequest` in lib/core/python/serverRec.py:
///
/// ```json
/// {
///   "logs": [[12, "2026-10-24T08:00:00.000", "had breakfast", "good"]],
///   "user_info": [["When do you usually wake up?", "07:30"]],
///   "goals": {"daily": ["drink water"], "weekly": [], "monthly": []},
///   "day": "2026-10-24T00:00:00.000"
/// }
/// ```
class InsightRequest {
  const InsightRequest({
    required this.kind,
    required this.day,
    required this.logs,
    required this.userInfo,
    required this.goals,
  });

  final InsightKind kind;
  final DateTime day;

  /// Oldest first.
  final List<InsightLog> logs;

  /// (assessment prompt, answer).
  final List<(String, String)> userInfo;
  final Map<GoalPeriod, List<String>> goals;

  /// Logs on [day] for a reflection; the last 14 days for recommendations
  /// (the same windows serverRec.py uses).
  List<InsightLog> get relevantLogs {
    if (kind == InsightKind.reflection) {
      return [for (final l in logs) if (_sameDay(l.timestamp, day)) l];
    }
    final start = DateTime.now().subtract(const Duration(days: 14));
    return [for (final l in logs) if (!l.timestamp.isBefore(start)) l];
  }

  Map<String, Object?> toJson() => {
        'logs': [for (final l in logs) l.toJson()],
        'user_info': [for (final (prompt, option) in userInfo) [prompt, option]],
        'goals': {for (final p in GoalPeriod.values) p.name: goals[p] ?? const <String>[]},
        'day': day.toIso8601String(),
      };

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// One `(id, timestamp, action, feeling)` tuple.
class InsightLog {
  const InsightLog({required this.id, required this.timestamp, required this.action, required this.feeling});

  factory InsightLog.fromEntry(LogEntry e, int fallbackId) {
    final digits = RegExp(r'\d+').firstMatch(e.entryId)?.group(0);
    return InsightLog(
      id: digits == null ? fallbackId : int.parse(digits),
      timestamp: DateTime(e.date.year, e.date.month, e.date.day, e.time.hour, e.time.minute),
      action: e.event,
      feeling: Happiness.phrase(e.happiness),
    );
  }

  final int id;
  final DateTime timestamp;
  final String action;

  /// Happiness label, e.g. "good". Also the key for `feeling_weights`.
  final String feeling;

  List<Object> toJson() => [id, timestamp.toIso8601String(), action, feeling];
}

/// Gathers logs, goals and assessment answers from the other repositories.
/// Shared by the mock and (later) the HTTP insights repository.
class InsightRequestBuilder {
  InsightRequestBuilder({
    required this._journal,
    required this._goals,
    required this._assessment,
  });

  /// Covers the reflection's 30-day progress window and the 8 weeks of
  /// same-weekday habits recommendations look at.
  static const historyDays = 56;

  final JournalRepository _journal;
  final GoalRepository _goals;
  final AssessmentRepository _assessment;

  Future<InsightRequest> build(InsightKind kind, DateTime day) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = await Future.wait([
      _journal.fetchEntries(from: DateTime(today.year, today.month, today.day - historyDays), to: today),
      _goals.fetch(),
      _assessment.fetchQuestions(),
      _assessment.fetchAnswers(),
    ]);
    final entries = results[0] as List<LogEntry>;
    final goals = results[1] as List<Goal>;
    final prompts = {for (final q in results[2] as List<AssessmentQuestion>) q.id: q.prompt};
    final answers = results[3] as List<AssessmentAnswer>;

    final logs = [for (final (i, e) in entries.indexed) InsightLog.fromEntry(e, i + 1)]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return InsightRequest(
      kind: kind,
      day: DateTime(day.year, day.month, day.day),
      logs: logs,
      userInfo: [
        for (final a in answers)
          if (prompts[a.questionId] case final prompt?) (prompt, a.value),
      ],
      goals: {for (final p in GoalPeriod.values) p: [for (final g in goals) if (g.period == p) g.text]},
    );
  }
}
