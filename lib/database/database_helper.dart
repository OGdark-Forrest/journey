
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_package_1/models/user_infor.dart';
import 'package:flutter_package_1/models/journal_prompt.dart';
import 'package:flutter_package_1/models/journal_entry.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_app.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Add journal tables without deleting existing user data.
        if (oldVersion < 3) {
          await _createJournalTables(db);
        }
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL CHECK (age >= 0),
        gender TEXT NOT NULL,
        employmentStatus TEXT NOT NULL CHECK (
          employmentStatus IN (
            'student', 'employed', 'unemployed',
            'self_employed', 'retired'
          )
        )
      )
    ''');

    await db.execute('''
      CREATE TABLE ui_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL UNIQUE,
        isDarkMode INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (userId)
          REFERENCES user_info(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE authentication (
        userId INTEGER PRIMARY KEY,
        authMethod TEXT NOT NULL,
        lastLoginAt TEXT,
        FOREIGN KEY (userId)
          REFERENCES user_info(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        action TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId)
          REFERENCES user_info(id) ON DELETE SET NULL
      )
    ''');

    await _createJournalTables(db);
  }

  Future<void> _createJournalTables(Database db) async {
    await db.execute('''
      CREATE TABLE journal_prompts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promptText TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        isActive INTEGER NOT NULL DEFAULT 1,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        promptText TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // ---------------- USER PROFILES ----------------

  Future<int> insertUser(UserInfo user) async {
    final db = await database;
    final values = user.toMap()..remove('id');
    return db.insert('user_info', values);
  }

  Future<List<UserInfo>> getUsers() async {
    final db = await database;
    final rows = await db.query(
      'user_info',
      orderBy: 'id DESC',
    );

    return rows.map((row) => UserInfo.fromMap(row)).toList();
  }

  Future<int> updateUser(UserInfo user) async {
    if (user.id == null) {
      throw ArgumentError('User id is required to update.');
    }

    final db = await database;
    final values = user.toMap()..remove('id');

    return db.update(
      'user_info',
      values,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(
      'user_info',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- UI PREFERENCES ----------------

  Future<int> saveUiInfo({
    required int userId,
    required bool isDarkMode,
  }) async {
    final db = await database;

    return db.insert(
      'ui_info',
      {
        'userId': userId,
        'isDarkMode': isDarkMode ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------- AUTHENTICATION ----------------

  Future<int> saveAuthentication({
    required int userId,
    required String authMethod,
    String? lastLoginAt,
  }) async {
    final db = await database;

    return db.insert(
      'authentication',
      {
        'userId': userId,
        'authMethod': authMethod,
        'lastLoginAt': lastLoginAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------- LOGS ----------------

  Future<int> addLog({
    int? userId,
    required String action,
  }) async {
    final db = await database;

    return db.insert('logs', {
      'userId': userId,
      'action': action,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await database;
    return db.query('logs', orderBy: 'id DESC');
  }

  // ---------------- JOURNAL PROMPTS ----------------

  Future<List<JournalPrompt>> getPrompts({
    String? category,
  }) async {
    final db = await database;

    final rows = await db.query(
      'journal_prompts',
      where: category == null
          ? 'isActive = ?'
          : 'isActive = ? AND category = ?',
      whereArgs: category == null ? [1] : [1, category],
      orderBy: 'sortOrder ASC, id DESC',
    );

    return rows.map((row) => JournalPrompt.fromMap(row)).toList();
  }

  Future<int> addPrompt({
    required String promptText,
    String category = 'General',
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('journal_prompts', {
      'promptText': promptText,
      'category': category,
      'isActive': 1,
      'sortOrder': 0,
      'createdAt': now,
    });
  }

  // ---------------- JOURNAL ENTRIES ----------------

  Future<List<JournalEntry>> getEntries() async {
    final db = await database;

    final rows = await db.query(
      'journal_entries',
      orderBy: 'updatedAt DESC',
    );

    return rows.map((row) => JournalEntry.fromMap(row)).toList();
  }

  Future<int> saveEntry({
    required String content,
    String? promptText,
    int? id,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      // Create a new journal entry.
      return db.insert('journal_entries', {
        'content': content,
        'promptText': promptText,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    // Edit an existing entry and preserve its original creation time.
    return db.update(
      'journal_entries',
      {
        'content': content,
        'promptText': promptText,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;

    return db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
