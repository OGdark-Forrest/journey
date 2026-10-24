import '../../models/assessment.dart';
import '../../models/day_info.dart';
import '../../models/entry.dart';
import '../../models/happiness.dart';
import '../../models/streak.dart';
import '../../models/time_slot.dart';
import '../../models/user_prefs.dart';

/// In-memory stand-in for the Python server so the UI can be built offline
/// before the backend branch lands.
///
/// TODO(backend): delete this file once `LocalApi*Repository` classes exist.
/// Everything here (questions, draft prediction, streak rule, seed history)
/// is owned by the Python algorithm in the real app.
///
/// State resets on every app restart: nothing is persisted.
class MockPythonBackend {
  MockPythonBackend({
    this.latency = const Duration(milliseconds: 250),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _seedHistory();
  }

  /// Flip to `true` to skip onboarding while working on other screens.
  // TODO(backend): replaced by `GET /assessment/status`.
  static const startWithAssessmentCompleted = false;

  /// Entries needed for a day to count toward the streak.
  // TODO(backend): server-side config value (`streakMinEntries`, default 1).
  static const streakMinEntries = 1;

  static const _template = 'At {time}, I {event} and felt {happiness}.';

  /// Simulated localhost round-trip so loading states are visible.
  final Duration latency;
  final DateTime Function() _clock;

  bool assessmentCompleted = startWithAssessmentCompleted;
  final Map<String, AssessmentAnswer> _answers = {};

  // TODO(backend): replaced by `GET /prefs`. Placeholder name until the
  // assessment sets the real one.
  UserPrefs prefs = const UserPrefs(
    displayName: 'Friend',
    entriesPerDay: UserPrefs.defaultEntriesPerDay,
    reminderTime: TimeSlot.hm(21, 0),
    theme: ThemePreference.system,
  );

  // TODO(backend): learned from the assessment, then from history.
  TimeSlot _usualWake = const TimeSlot.hm(7, 30);
  final Map<String, TimeSlot> _wakeTimes = {};
  final List<LogEntry> _entries = [];
  int _ids = 0;

  Future<void> roundTrip() => Future<void>.delayed(latency);

  DateTime get _today => _dateOnly(_clock());

  // ---------------------------------------------------------------------------
  // Assessment
  // ---------------------------------------------------------------------------

  // TODO(backend): replaced by `GET /assessment/questions`. Time options use
  // the API `HH:mm` format; the UI formats them for display.
  List<AssessmentQuestion> get questions => const [
        AssessmentQuestion(
          id: 'display_name',
          prompt: 'What should we call you?',
          subtitle: 'Just a first name or nickname.',
          type: QuestionType.text,
          hint: 'Your name',
        ),
        AssessmentQuestion(
          id: 'usual_wake_time',
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

  void submitAssessment(List<AssessmentAnswer> answers) {
    for (final a in answers) {
      _answers[a.questionId] = a;
    }
    final name = _answers['display_name']?.value.trim();
    if (name != null && name.isNotEmpty) prefs = prefs.copyWith(displayName: name);
    final wake = _answers['usual_wake_time']?.value;
    if (wake != null) _usualWake = TimeSlot.parse(wake);
    assessmentCompleted = true;
  }

  // ---------------------------------------------------------------------------
  // Entries
  // ---------------------------------------------------------------------------

  // TODO(backend): replaced by the Python prediction behind `GET /entries/draft`.
  // This fake just buckets by time of day and picks the most frequent past event.
  EntryDraft draft(EntryMode mode) {
    final now = TimeSlot.nowRounded();
    final options = _optionsFor(now);
    final history = _entries.where((e) => options.contains(e.event)).map((e) => e.event);
    final counts = <String, int>{};
    for (final e in history) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final eventDefault = counts.isEmpty
        ? options.first
        : (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

    final recent = _entries.take(5).map((e) => e.happiness).toList();
    final happinessDefault = recent.isEmpty
        ? Happiness.neutral
        : (recent.reduce((a, b) => a + b) / recent.length).round();

    return EntryDraft(
      draftId: 'd_${++_ids}',
      mode: mode,
      indexToday: _entriesOn(_today).length + 1,
      entriesPerDay: prefs.entriesPerDay,
      template: _template,
      timeDefault: now,
      intervalMinutes: 30,
      happinessMin: Happiness.min,
      happinessMax: Happiness.max,
      happinessDefault: happinessDefault,
      eventDefault: eventDefault,
      eventOptions: options,
      allowCustom: true,
    );
  }

  SaveEntryResult save(NewEntry entry) {
    final saved = _makeEntry(
      date: _today,
      time: entry.time.value,
      event: entry.event.value,
      happiness: entry.happiness.value,
      mode: entry.mode,
    );
    _entries.insert(0, saved);
    _sortEntries();
    return SaveEntryResult(
      entryId: saved.entryId,
      indexToday: _entriesOn(_today).length,
      streak: streak(),
    );
  }

  List<LogEntry> entriesBetween(DateTime from, DateTime to) {
    final f = _dateOnly(from);
    final t = _dateOnly(to);
    return _entries.where((e) => !e.date.isBefore(f) && !e.date.isAfter(t)).toList();
  }

  // TODO(backend): replaced by `GET /streak` (server owns the rule).
  StreakInfo streak() {
    final perDay = <DateTime, int>{};
    for (final e in _entries) {
      perDay[e.date] = (perDay[e.date] ?? 0) + 1;
    }
    bool counts(DateTime d) => (perDay[d] ?? 0) >= streakMinEntries;

    // Today not logged yet doesn't break the streak; it's still "alive".
    var cursor = counts(_today) ? _today : _prevDay(_today);
    var current = 0;
    while (counts(cursor)) {
      current++;
      cursor = _prevDay(cursor);
    }

    final days = perDay.keys.where(counts).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? last;
    for (final d in days) {
      run = (last != null && _prevDay(d) == last) ? run + 1 : 1;
      if (run > best) best = run;
      last = d;
    }

    return StreakInfo(
      current: current,
      best: best < current ? current : best,
      loggedToday: perDay[_today] ?? 0,
      entriesPerDay: prefs.entriesPerDay,
      streakMinEntries: streakMinEntries,
    );
  }

  // ---------------------------------------------------------------------------
  // Day / wake time
  // ---------------------------------------------------------------------------

  DayInfo day(DateTime date) {
    final d = _dateOnly(date);
    return DayInfo(date: d, wakeTime: _wakeTimes[_key(d)], wakeTimeDefault: _usualWake);
  }

  DayInfo setWakeTime(DateTime date, FieldValue<TimeSlot> wake) {
    _wakeTimes[_key(_dateOnly(date))] = wake.value;
    return day(date);
  }

  // ---------------------------------------------------------------------------
  // Helpers + seed data
  // ---------------------------------------------------------------------------

  // TODO(backend): event options come from the user's history in the real draft.
  static List<String> _optionsFor(TimeSlot t) {
    final h = t.hour;
    if (h >= 5 && h < 11) return ['had breakfast', 'had coffee', 'worked out', 'commuted'];
    if (h >= 11 && h < 14) return ['had lunch', 'worked', 'studied', 'ran errands'];
    if (h >= 14 && h < 17) return ['worked', 'went for a walk', 'studied', 'took a break'];
    if (h >= 17 && h < 21) return ['had dinner', 'relaxed', 'met a friend', 'exercised'];
    return ['read', 'watched something', 'scrolled my phone', 'got ready for bed'];
  }

  // TODO(backend): seed history is fake; real history comes from `GET /entries`.
  void _seedHistory() {
    const seed = <int, List<(String, String, int)>>{
      1: [
        ('08:00', 'had breakfast', 3),
        ('12:30', 'had lunch', 4),
        ('15:00', 'worked', 3),
        ('19:00', 'had dinner', 4),
        ('22:00', 'read', 5),
      ],
      2: [
        ('08:30', 'had breakfast', 3),
        ('13:00', 'had lunch', 3),
        ('18:00', 'went for a walk', 5),
        ('21:30', 'scrolled my phone', 2),
      ],
      3: [
        ('07:30', 'worked out', 4),
        ('12:00', 'had lunch', 4),
        ('20:00', 'met a friend', 5),
      ],
      4: [
        ('09:00', 'had coffee', 3),
        ('14:00', 'studied', 2),
        ('19:30', 'had dinner', 4),
      ],
      6: [
        ('10:00', 'had breakfast', 3),
        ('16:00', 'took a break', 1),
      ],
    };
    final today = _today;
    seed.forEach((daysAgo, items) {
      final date = DateTime(today.year, today.month, today.day - daysAgo);
      _wakeTimes[_key(date)] = _usualWake;
      for (final (time, event, happiness) in items) {
        _entries.add(_makeEntry(
          date: date,
          time: TimeSlot.parse(time),
          event: event,
          happiness: happiness,
          mode: happiness.isEven ? EntryMode.blitz : EntryMode.normal,
        ));
      }
    });
    _sortEntries();
  }

  LogEntry _makeEntry({
    required DateTime date,
    required TimeSlot time,
    required String event,
    required int happiness,
    required EntryMode mode,
  }) {
    final text = _template
        .replaceAll('{time}', time.toLabel12h())
        .replaceAll('{event}', event)
        .replaceAll('{happiness}', Happiness.phrase(happiness));
    return LogEntry(
      entryId: 'e_${++_ids}',
      date: _dateOnly(date),
      time: time,
      mode: mode,
      happiness: happiness,
      event: event,
      text: text,
    );
  }

  List<LogEntry> _entriesOn(DateTime d) => _entries.where((e) => e.date == d).toList();

  void _sortEntries() {
    _entries.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.time.compareTo(a.time);
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _prevDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
