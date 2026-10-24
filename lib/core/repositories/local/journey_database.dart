import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/user_prefs.dart';

/// On-device SQLite storage for Journey, shared by the `Sqflite*Repository`
/// classes. Opened lazily on first use.
///
/// Schema (v1):
/// - `entries`            one row per logged event (time, happiness, event)
///                        plus the per-field `keptDefault` learning signal.
/// - `day_info`           the once-a-day wake-up time.
/// - `prefs`              single row (id = 1) of user preferences.
/// - `assessment_answers` onboarding answers, keyed by question id.
///
/// Dates are stored as `YYYY-MM-DD`, times as `HH:mm`, timestamps as ISO 8601,
/// matching .kiro/steering/api-contract.md so Python can read the same data.
class JourneyDatabase {
  JourneyDatabase({this.fileName = 'journey.db'});

  /// Bump this and add an `onUpgrade` step for every schema change.
  /// Never drop tables in an upgrade: this is the user's journal.
  static const schemaVersion = 1;

  final String fileName;
  Future<Database>? _db;

  /// Caches the Future (not the Database) so concurrent first calls open the
  /// file only once. A failed open is cleared so the next call can retry.
  Future<Database> get database {
    return _db ??= _open().catchError((Object error, StackTrace stack) {
      _db = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, fileName),
      version: schemaVersion,
      onCreate: _create,
    );
  }

  static Future<void> _create(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        draftId TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        mode TEXT NOT NULL CHECK (mode IN ('normal', 'blitz')),
        happiness INTEGER NOT NULL CHECK (happiness BETWEEN 1 AND 5),
        event TEXT NOT NULL CHECK (length(trim(event)) > 0),
        eventCustom INTEGER NOT NULL DEFAULT 0 CHECK (eventCustom IN (0, 1)),
        timeKeptDefault INTEGER NOT NULL CHECK (timeKeptDefault IN (0, 1)),
        happinessKeptDefault INTEGER NOT NULL CHECK (happinessKeptDefault IN (0, 1)),
        eventKeptDefault INTEGER NOT NULL CHECK (eventKeptDefault IN (0, 1)),
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_entries_date_time ON entries (date, time)');

    batch.execute('''
      CREATE TABLE day_info (
        date TEXT PRIMARY KEY,
        wakeTime TEXT NOT NULL,
        wakeKeptDefault INTEGER NOT NULL CHECK (wakeKeptDefault IN (0, 1)),
        updatedAt TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE prefs (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        displayName TEXT NOT NULL,
        entriesPerDay INTEGER NOT NULL CHECK (
          entriesPerDay BETWEEN ${UserPrefs.minEntriesPerDay} AND ${UserPrefs.maxEntriesPerDay}
        ),
        reminderTime TEXT,
        theme TEXT NOT NULL CHECK (theme IN ('system', 'light', 'dark'))
      )
    ''');

    batch.execute('''
      CREATE TABLE assessment_answers (
        questionId TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        custom INTEGER NOT NULL DEFAULT 0 CHECK (custom IN (0, 1)),
        answeredAt TEXT NOT NULL
      )
    ''');

    // Default prefs row. Display name is replaced by the assessment answer.
    batch.insert('prefs', {
      'id': 1,
      'displayName': 'Friend',
      'entriesPerDay': UserPrefs.defaultEntriesPerDay,
      'reminderTime': '21:00',
      'theme': ThemePreference.system.name,
    });

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final pending = _db;
    _db = null;
    if (pending != null) await (await pending).close();
  }
}
