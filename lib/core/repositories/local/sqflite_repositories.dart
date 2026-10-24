import 'package:sqflite/sqflite.dart';

import '../../models/assessment.dart';
import '../../models/day_info.dart';
import '../../models/entry.dart';
import '../../models/happiness.dart';
import '../../models/streak.dart';
import '../../models/time_slot.dart';
import '../../models/user_prefs.dart';
import '../repositories.dart';
import 'journey_database.dart';
import 'local_rules.dart';

// On-device implementations of the repository interfaces, backed by SQLite.
// Unlike the Mock* classes, data survives app restarts.
//
// TODO(backend): if Python ends up owning the DB, replace these with
// `LocalApi*Repository` (HTTP). If Flutter owns storage, keep these and move
// only the prediction logic in LocalRules to Python.

class SqfliteAssessmentRepository implements AssessmentRepository {
  SqfliteAssessmentRepository(this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final JourneyDatabase _store;
  final DateTime Function() _clock;

  @override
  Future<List<AssessmentQuestion>> fetchQuestions() async => LocalRules.questions;

  @override
  Future<void> submit(List<AssessmentAnswer> answers) async {
    final db = await _store.database;
    final now = _clock().toIso8601String();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final a in answers) {
        batch.insert(
          'assessment_answers',
          {
            'questionId': a.questionId,
            'value': a.value,
            'custom': a.custom ? 1 : 0,
            'answeredAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final name = _answer(answers, LocalRules.displayNameQuestion)?.trim();
      if (name != null && name.isNotEmpty) {
        batch.update('prefs', {'displayName': name}, where: 'id = 1');
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<bool> isCompleted() async {
    final db = await _store.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM assessment_answers'),
    );
    return (count ?? 0) > 0;
  }

  static String? _answer(List<AssessmentAnswer> answers, String id) {
    for (final a in answers) {
      if (a.questionId == id) return a.value;
    }
    return null;
  }
}

class SqfliteJournalRepository implements JournalRepository {
  SqfliteJournalRepository(this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final JourneyDatabase _store;
  final DateTime Function() _clock;

  DateTime get _today => LocalRules.dateOnly(_clock());

  // TODO(backend): replaced by the Python prediction behind `GET /entries/draft`.
  // Local heuristic: time-of-day presets, defaulting to the user's most
  // frequent past event among them and their recent average happiness.
  @override
  Future<EntryDraft> fetchDraft(EntryMode mode) async {
    final db = await _store.database;
    final now = _clock();
    final slot = TimeSlot.nowRounded(intervalMinutes: LocalRules.intervalMinutes, now: now);
    final options = LocalRules.eventOptionsFor(slot);

    final placeholders = List.filled(options.length, '?').join(', ');
    final topEvent = await db.rawQuery(
      'SELECT event, COUNT(*) AS uses FROM entries WHERE event IN ($placeholders) '
      'GROUP BY event ORDER BY uses DESC, MAX(id) DESC LIMIT 1',
      options,
    );

    final recent = await db.query(
      'entries',
      columns: ['happiness'],
      orderBy: 'date DESC, time DESC, id DESC',
      limit: 5,
    );

    final prefs = await _readPrefs(db);
    final loggedToday = await _countOn(db, _today);

    return EntryDraft(
      draftId: 'd_${now.microsecondsSinceEpoch}',
      mode: mode,
      indexToday: loggedToday + 1,
      entriesPerDay: prefs.entriesPerDay,
      template: LocalRules.template,
      timeDefault: slot,
      intervalMinutes: LocalRules.intervalMinutes,
      happinessMin: Happiness.min,
      happinessMax: Happiness.max,
      happinessDefault: LocalRules.defaultHappiness(
        [for (final row in recent) row['happiness']! as int],
      ),
      eventDefault: topEvent.isEmpty ? options.first : topEvent.first['event']! as String,
      eventOptions: options,
      allowCustom: true,
    );
  }

  @override
  Future<SaveEntryResult> saveEntry(NewEntry entry) async {
    final event = entry.event.value.trim();
    final happiness = entry.happiness.value;
    if (event.isEmpty) throw ArgumentError.value(entry.event.value, 'event', 'must not be empty');
    if (happiness < Happiness.min || happiness > Happiness.max) {
      throw RangeError.range(happiness, Happiness.min, Happiness.max, 'happiness');
    }

    final db = await _store.database;
    final today = _today;

    final id = await db.insert('entries', {
      'draftId': entry.draftId,
      'date': LocalRules.dateKey(today),
      'time': entry.time.value.toApi(),
      'mode': entry.mode.apiName,
      'happiness': happiness,
      'event': event,
      'eventCustom': entry.event.custom ? 1 : 0,
      'timeKeptDefault': entry.time.keptDefault ? 1 : 0,
      'happinessKeptDefault': entry.happiness.keptDefault ? 1 : 0,
      'eventKeptDefault': entry.event.keptDefault ? 1 : 0,
      'text': LocalRules.sentence(time: entry.time.value, event: event, happiness: happiness),
      'createdAt': _clock().toIso8601String(),
    });

    return SaveEntryResult(
      entryId: 'e_$id',
      indexToday: await _countOn(db, today),
      streak: await _streak(db),
    );
  }

  @override
  Future<List<LogEntry>> fetchEntries({required DateTime from, required DateTime to}) async {
    final db = await _store.database;
    final rows = await db.query(
      'entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [LocalRules.dateKey(from), LocalRules.dateKey(to)],
      orderBy: 'date DESC, time DESC, id DESC',
    );
    return rows.map(_toLogEntry).toList();
  }

  @override
  Future<StreakInfo> fetchStreak() async => _streak(await _store.database);

  @override
  Future<DayInfo> fetchDay(DateTime date) async {
    final db = await _store.database;
    final d = LocalRules.dateOnly(date);
    final rows = await db.query(
      'day_info',
      columns: ['wakeTime'],
      where: 'date = ?',
      whereArgs: [LocalRules.dateKey(d)],
      limit: 1,
    );
    return DayInfo(
      date: d,
      wakeTime: rows.isEmpty ? null : TimeSlot.parse(rows.first['wakeTime']! as String),
      wakeTimeDefault: await _usualWake(db),
      intervalMinutes: LocalRules.intervalMinutes,
    );
  }

  @override
  Future<DayInfo> saveWakeTime(DateTime date, FieldValue<TimeSlot> wakeTime) async {
    final db = await _store.database;
    await db.insert(
      'day_info',
      {
        'date': LocalRules.dateKey(LocalRules.dateOnly(date)),
        'wakeTime': wakeTime.value.toApi(),
        'wakeKeptDefault': wakeTime.keptDefault ? 1 : 0,
        'updatedAt': _clock().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return fetchDay(date);
  }

  Future<StreakInfo> _streak(Database db) async {
    final rows = await db.rawQuery('SELECT date, COUNT(*) AS n FROM entries GROUP BY date');
    final prefs = await _readPrefs(db);
    return LocalRules.streak(
      entriesPerDate: {
        for (final row in rows) LocalRules.parseDateKey(row['date']! as String): row['n']! as int,
      },
      today: _today,
      entriesPerDay: prefs.entriesPerDay,
    );
  }

  static Future<int> _countOn(Database db, DateTime day) async {
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM entries WHERE date = ?',
      [LocalRules.dateKey(day)],
    ));
    return count ?? 0;
  }

  // TODO(backend): learned from history by the Python algorithm. Locally it
  // comes from the assessment answer only.
  static Future<TimeSlot> _usualWake(Database db) async {
    final rows = await db.query(
      'assessment_answers',
      columns: ['value'],
      where: 'questionId = ?',
      whereArgs: [LocalRules.usualWakeQuestion],
      limit: 1,
    );
    if (rows.isEmpty) return LocalRules.defaultUsualWake;
    try {
      return TimeSlot.parse(rows.first['value']! as String);
    } on FormatException {
      return LocalRules.defaultUsualWake;
    }
  }

  static LogEntry _toLogEntry(Map<String, Object?> row) {
    return LogEntry(
      entryId: 'e_${row['id']}',
      date: LocalRules.parseDateKey(row['date']! as String),
      time: TimeSlot.parse(row['time']! as String),
      mode: EntryMode.fromApi(row['mode'] as String?),
      happiness: row['happiness']! as int,
      event: row['event']! as String,
      text: row['text']! as String,
    );
  }
}

class SqflitePrefsRepository implements PrefsRepository {
  SqflitePrefsRepository(this._store);

  final JourneyDatabase _store;

  @override
  Future<UserPrefs> fetch() async => _readPrefs(await _store.database);

  @override
  Future<UserPrefs> save(UserPrefs prefs) async {
    final db = await _store.database;
    await db.update(
      'prefs',
      {
        'displayName': prefs.displayName,
        'entriesPerDay': prefs.entriesPerDay.clamp(
          UserPrefs.minEntriesPerDay,
          UserPrefs.maxEntriesPerDay,
        ),
        'reminderTime': prefs.reminderTime?.toApi(),
        'theme': prefs.theme.name,
      },
      where: 'id = 1',
    );
    return _readPrefs(db);
  }
}

Future<UserPrefs> _readPrefs(DatabaseExecutor db) async {
  final rows = await db.query('prefs', where: 'id = 1', limit: 1);
  if (rows.isEmpty) throw StateError('prefs row missing; database was not initialised');
  final row = rows.first;
  final reminder = row['reminderTime'] as String?;
  return UserPrefs(
    displayName: row['displayName']! as String,
    entriesPerDay: row['entriesPerDay']! as int,
    reminderTime: reminder == null ? null : TimeSlot.parse(reminder),
    theme: ThemePreference.values.asNameMap()[row['theme']] ?? ThemePreference.system,
  );
}
