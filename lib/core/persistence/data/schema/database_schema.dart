import 'package:sqflite/sqflite.dart';

abstract final class DatabaseSchema {
  static const version = 1;
  static const routineRecords = 'routine_records';
  static const routineStepRecords = 'routine_step_records';
  static const appSettings = 'app_settings';

  static Future<void> create(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $routineRecords (
        date_key TEXT NOT NULL,
        routine_id TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('partial', 'completed', 'notToday')),
        completed_at_utc TEXT,
        recorded_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        not_today_reason TEXT,
        PRIMARY KEY (date_key, routine_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE $routineStepRecords (
        date_key TEXT NOT NULL,
        routine_id TEXT NOT NULL,
        step_id TEXT NOT NULL,
        is_completed INTEGER NOT NULL CHECK (is_completed IN (0, 1)),
        completed_at_utc TEXT,
        recorded_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        PRIMARY KEY (date_key, routine_id, step_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE $appSettings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        theme_mode TEXT NOT NULL CHECK (theme_mode IN ('system', 'light', 'dark')),
        reminders_enabled INTEGER NOT NULL CHECK (reminders_enabled IN (0, 1)),
        updated_at_utc TEXT NOT NULL
      )
    ''');
    await db.insert(appSettings, {
      'id': 1,
      'theme_mode': 'system',
      'reminders_enabled': 0,
      'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> upgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1 && newVersion >= 1) await create(db);
  }
}
