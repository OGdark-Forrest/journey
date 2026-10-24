import '../../models/assessment.dart';
import '../../models/happiness.dart';
import '../../models/streak.dart';
import '../../models/time_slot.dart';

/// Content and rules the on-device repositories need until the Python
/// algorithm exists. Mirrors the behaviour of `MockPythonBackend` but runs
/// against stored data instead of fake in-memory history.
///
/// TODO(backend): everything here is owned by the Python algorithm in the real
/// app (`GET /assessment/questions`, `GET /entries/draft`, `GET /streak`).
/// Keep it in sync with mock/mock_python_backend.dart until then.
abstract final class LocalRules {
  static const template = 'At {time}, I {event} and felt {happiness}.';

  /// Entries needed for a day to count toward the streak (server config).
  static const streakMinEntries = 1;

  static const intervalMinutes = 30;

  /// Fallback until the assessment provides the user's usual wake time.
  static const defaultUsualWake = TimeSlot.hm(7, 30);

  static const displayNameQuestion = 'display_name';
  static const usualWakeQuestion = 'usual_wake_time';

  static const questions = [
    AssessmentQuestion(
      id: displayNameQuestion,
      prompt: 'What should we call you?',
      subtitle: 'Just a first name or nickname.',
      type: QuestionType.text,
      hint: 'Your name',
    ),
    AssessmentQuestion(
      id: usualWakeQuestion,
      prompt: 'When do you usually wake up?',
      subtitle: 'We\'ll use this as your default each morning.',
      type: QuestionType.time,
      options: ['06:00', '07:00', '07:30', '08:00'],
      allowCustom: true,
    ),
    AssessmentQuestion(
      id: 'wake_feeling',
      prompt: 'How do you usually feel when you wake up?',
      type: QuestionType.single,
      options: ['Groggy', 'Okay', 'Rested', 'Wide awake'],
      allowCustom: true,
      hint: 'e.g. depends on the day',
    ),
    AssessmentQuestion(
      id: 'day_focus',
      prompt: 'What fills most of your day?',
      type: QuestionType.single,
      options: ['Work', 'School', 'Home & family', 'A mix'],
      allowCustom: true,
      hint: 'e.g. training, caregiving',
    ),
    AssessmentQuestion(
      id: 'meals',
      prompt: 'How do you usually eat?',
      type: QuestionType.single,
      options: ['1-2 meals', '3 meals', '3 meals + snacks', 'It varies a lot'],
      allowCustom: true,
    ),
    AssessmentQuestion(
      id: 'movement',
      prompt: 'How often do you move or exercise?',
      type: QuestionType.single,
      options: ['Rarely', '1-2 times a week', '3-4 times a week', 'Most days'],
    ),
    AssessmentQuestion(
      id: 'unwind',
      prompt: 'How do you like to unwind?',
      subtitle: 'Pick as many as you like.',
      type: QuestionType.multi,
      options: ['Reading', 'Screens & shows', 'Being with people', 'Getting outside'],
      allowCustom: true,
      hint: 'e.g. cooking',
    ),
    AssessmentQuestion(
      id: 'usual_bed_time',
      prompt: 'And when do you usually go to bed?',
      type: QuestionType.time,
      options: ['22:00', '23:00', '00:00', '01:00'],
      allowCustom: true,
    ),
  ];

  /// ~4 event presets for the time of day.
  static List<String> eventOptionsFor(TimeSlot t) {
    final h = t.hour;
    if (h >= 5 && h < 11) return const ['had breakfast', 'had coffee', 'worked out', 'commuted'];
    if (h >= 11 && h < 14) return const ['had lunch', 'worked', 'studied', 'ran errands'];
    if (h >= 14 && h < 17) return const ['worked', 'went for a walk', 'studied', 'took a break'];
    if (h >= 17 && h < 21) return const ['had dinner', 'relaxed', 'met a friend', 'exercised'];
    return const ['read', 'watched something', 'scrolled my phone', 'got ready for bed'];
  }

  /// Average of the most recent happiness values, or neutral with no history.
  static int defaultHappiness(List<int> recent) {
    if (recent.isEmpty) return Happiness.neutral;
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    return avg.round().clamp(Happiness.min, Happiness.max);
  }

  /// The final journal sentence shown in the dashboard history.
  static String sentence({required TimeSlot time, required String event, required int happiness}) {
    return template
        .replaceAll('{time}', time.toLabel12h())
        .replaceAll('{event}', event)
        .replaceAll('{happiness}', Happiness.phrase(happiness));
  }

  /// Streak from entry counts per calendar day. Today not being logged yet
  /// doesn't break the streak; it's still "alive".
  static StreakInfo streak({
    required Map<DateTime, int> entriesPerDate,
    required DateTime today,
    required int entriesPerDay,
  }) {
    final todayDate = dateOnly(today);
    bool counts(DateTime d) => (entriesPerDate[d] ?? 0) >= streakMinEntries;

    var cursor = counts(todayDate) ? todayDate : prevDay(todayDate);
    var current = 0;
    while (counts(cursor)) {
      current++;
      cursor = prevDay(cursor);
    }

    final days = entriesPerDate.keys.where(counts).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? last;
    for (final d in days) {
      run = (last != null && prevDay(d) == last) ? run + 1 : 1;
      if (run > best) best = run;
      last = d;
    }

    return StreakInfo(
      current: current,
      best: best < current ? current : best,
      loggedToday: entriesPerDate[todayDate] ?? 0,
      entriesPerDay: entriesPerDay,
      streakMinEntries: streakMinEntries,
    );
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime prevDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

  /// API/storage date format `YYYY-MM-DD`.
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Parses `YYYY-MM-DD` as a local calendar day.
  static DateTime parseDateKey(String key) => dateOnly(DateTime.parse(key));
}
