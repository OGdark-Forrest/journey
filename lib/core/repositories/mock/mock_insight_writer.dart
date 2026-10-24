import '../../models/goal.dart';
import '../../models/insight.dart';
import '../../models/time_slot.dart';
import '../insight_request.dart';

/// Stand-in for the Gemini call in lib/core/python/model.py. Writes simple,
/// data-driven text with exactly the headings the serverRec.py prompts ask
/// for, so the UI parses the same shape it will get from the real model.
///
/// TODO(backend): delete once the insights endpoints are wired up.
abstract final class MockInsightWriter {
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Happiness labels (Happiness.phrase) -> 1-5.
  static const _feelingScore = {'rough': 1, 'low': 2, 'okay': 3, 'good': 4, 'great': 5};

  // ---------------------------------------------------------------------------
  // Reflection
  // ---------------------------------------------------------------------------

  static String reflection(InsightRequest req) {
    final day = req.relevantLogs;
    if (day.isEmpty) {
      // Same sentence serverRec.getReflection returns without calling the model.
      return 'No activity was logged for ${_weekdays[req.day.weekday - 1]}, '
          '${_months[req.day.month - 1]} ${req.day.day.toString().padLeft(2, '0')}, '
          'so there\'s nothing to reflect on yet.';
    }

    final best = day.reduce((a, b) => _score(b) > _score(a) ? b : a);
    final worst = day.reduce((a, b) => _score(b) < _score(a) ? b : a);
    final avg = day.map(_score).reduce((a, b) => a + b) / day.length;
    final score = (avg * 2).round().clamp(1, 10);
    final daily = req.goals[GoalPeriod.daily] ?? const [];

    final b = StringBuffer()..writeln('## ${Insight.goalAlignment}');
    if (daily.isEmpty) {
      b.writeln('You haven\'t set a daily goal yet, so this is a look at the day itself. '
          'Adding one on the dashboard gives the next reflection something to measure against.');
    } else {
      for (final goal in daily) {
        final hit = day.where((l) => _overlaps(l.action, goal)).toList();
        b.writeln(hit.isEmpty
            ? '- Nothing logged clearly lines up with **$goal** yet.'
            : '- **$goal**: you ${hit.first.action} at ${_time(hit.first)}, which counts toward it.');
      }
    }
    b
      ..writeln('- The high point was **${best.action}** at ${_time(best)}, when you felt ${best.feeling}.')
      ..writeln()
      ..writeln('## ${Insight.overallFeeling}')
      ..writeln('Happiness score: **$score/10**.')
      ..writeln(day.length > 1
          ? 'You started the day feeling ${day.first.feeling} and ended it feeling ${day.last.feeling}. '
              'Across ${day.length} entries your mood averaged ${_word(avg)}.'
          : 'You logged one moment today and felt ${day.first.feeling}. That\'s a small sample, so take the score lightly.')
      ..writeln()
      ..writeln('## ${Insight.couldBeBetter}');

    final tips = <String>[
      if (_score(worst) <= 2 && worst != best)
        '**${_cap(worst.action)}** at ${_time(worst)} felt ${worst.feeling}. Next time, try following it '
            'with something that lifted you, like ${best.action}.',
      if (day.length < 3)
        'Only ${day.length} ${day.length == 1 ? 'entry was' : 'entries were'} logged. A couple more check-ins '
            'would make tomorrow\'s reflection sharper.',
      if (daily.isNotEmpty && !day.any((l) => daily.any((g) => _overlaps(l.action, g))))
        'Block out a short slot for **${daily.first}** tomorrow so it doesn\'t get crowded out.',
      'Keep **${best.action}** in your week. It was the brightest part of today.',
      'End the evening with something calm and screen-free to wind down.',
    ];
    for (final t in tips.take(4)) {
      b.writeln('- $t');
    }
    return b.toString();
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  static String recommendations(InsightRequest req) {
    final recent = req.relevantLogs;
    final cutoff = req.day.subtract(const Duration(days: 56));
    final sameWeekday = [
      for (final l in req.logs)
        if (l.timestamp.weekday == req.day.weekday && l.timestamp.isAfter(cutoff)) l,
    ];
    final weekday = _weekdays[req.day.weekday - 1];

    final b = StringBuffer();
    if (req.logs.length < 5) {
      b
        ..writeln('There isn\'t much history yet, so this plan keeps things simple.')
        ..writeln();
    }
    b.writeln('## ${Insight.dayPlan}');
    for (final part in DayPart.values) {
      b.writeln('**${part.label}**');
      final picks = _top(sameWeekday, part);
      final fallback = picks.isEmpty ? _top(req.logs, part) : const <(String, double)>[];
      final items = [...picks, ...fallback].take(3).toList();
      if (items.isEmpty) {
        b.writeln('- ${_defaults[part]}');
      }
      for (final (action, mood) in items) {
        final why = picks.isNotEmpty ? 'a $weekday habit' : 'something you do often';
        b.writeln('- ${_imperative(action)} ($why${mood >= 4 ? ', and it usually feels ${_word(mood)}' : ''})');
      }
    }

    final avg = recent.isEmpty ? 3.0 : recent.map(_score).reduce((a, b) => a + b) / recent.length;
    final daily = req.goals[GoalPeriod.daily] ?? const [];
    final weekly = req.goals[GoalPeriod.weekly] ?? const [];
    final focus = [...daily, ...weekly].take(2).toList();
    final type = avg < 2.8
        ? DayType.rest
        : (avg >= 3.6 && focus.isNotEmpty ? DayType.push : DayType.balanced);

    b
      ..writeln()
      ..writeln('## ${Insight.goalFocus}')
      ..writeln('**This looks like a ${type.label.toLowerCase()}.** ${switch (type) {
        DayType.rest => 'Your recent entries have averaged ${_word(avg)}, so go easy and protect the things that recharge you.',
        DayType.push => 'You\'ve been feeling ${_word(avg)} lately, which is good energy to put toward your goals.',
        DayType.balanced => 'Your mood has been steady (${_word(avg)} on average), so mix a bit of progress with your usual routine.',
      }}');
    if (focus.isEmpty) {
      b.writeln('- Set a daily or weekly goal on the dashboard and the plan will start steering toward it.');
    } else {
      for (final g in focus) {
        b.writeln('- Make room for **$g**.');
      }
    }
    return b.toString();
  }

  static const _defaults = {
    DayPart.morning: 'Start slow with breakfast and some daylight',
    DayPart.afternoon: 'Take a short walk or break between tasks',
    DayPart.evening: 'Wind down with something you enjoy',
  };

  /// Top actions in [part], ranked by count weighted by how they felt.
  static List<(String, double)> _top(List<InsightLog> logs, DayPart part) {
    final counts = <String, List<int>>{};
    for (final l in logs) {
      if (_partOf(l.timestamp.hour) == part) (counts[l.action] ??= []).add(_score(l));
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        double rank(List<int> s) => s.length * (s.reduce((x, y) => x + y) / s.length);
        return rank(b.value).compareTo(rank(a.value));
      });
    return [
      for (final e in ranked.take(3)) (e.key, e.value.reduce((x, y) => x + y) / e.value.length),
    ];
  }

  // Same blocks as serverRec.time_block; night (22-5) counts as evening.
  static DayPart _partOf(int hour) {
    if (hour >= 5 && hour < 12) return DayPart.morning;
    if (hour >= 12 && hour < 17) return DayPart.afternoon;
    return DayPart.evening;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static int _score(InsightLog l) => _feelingScore[l.feeling] ?? 3;

  static String _word(double avg) => switch (avg.round()) {
        <= 1 => 'rough',
        2 => 'low',
        3 => 'okay',
        4 => 'good',
        _ => 'great',
      };

  static String _time(InsightLog l) => TimeSlot.hm(l.timestamp.hour, l.timestamp.minute).toLabel12h();

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static const _verbs = {
    'had': 'Have', 'went': 'Go', 'worked': 'Work', 'met': 'Meet', 'read': 'Read',
    'watched': 'Watch', 'studied': 'Study', 'took': 'Take', 'ran': 'Run', 'commuted': 'Commute',
    'relaxed': 'Relax', 'exercised': 'Exercise', 'scrolled': 'Scroll', 'got': 'Get',
  };

  /// "had breakfast" -> "Have breakfast".
  static String _imperative(String action) {
    final words = action.split(' ');
    final verb = _verbs[words.first.toLowerCase()];
    return verb == null ? _cap(action) : [verb, ...words.skip(1)].join(' ');
  }

  /// Loose match between a logged action and a goal ("went for a walk" ~ "walk daily").
  static bool _overlaps(String action, String goal) {
    const stop = {'a', 'an', 'the', 'for', 'to', 'of', 'my', 'i', 'and', 'with', 'go', 'went', 'had', 'have'};
    Set<String> words(String s) => {
          for (final w in s.toLowerCase().split(RegExp(r'[^a-z]+')))
            if (w.length > 2 && !stop.contains(w)) w,
        };
    return words(action).intersection(words(goal)).isNotEmpty;
  }
}
