import 'package:sqflite/sqflite.dart';

abstract final class DatabaseSchema {
  static const version = 8;
  static const routineRecords = 'routine_records';
  static const routineStepRecords = 'routine_step_records';
  static const appSettings = 'app_settings';
  static const routineReminderStates = 'routine_reminder_states';
  static const routineDefinitions = 'routine_definitions';
  static const routineStepDefinitions = 'routine_step_definitions';
  static const dailyReflections = 'daily_reflections';
  static const syncMetadata = 'sync_metadata';
  static const syncOutbox = 'sync_outbox';
  static const routineContents = 'routine_contents';
  static const routineAttachments = 'routine_attachments';

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
        language_mode TEXT NOT NULL DEFAULT 'system'
          CHECK (language_mode IN ('system', 'id', 'en')),
        reminders_enabled INTEGER NOT NULL CHECK (reminders_enabled IN (0, 1)),
        onboarding_version INTEGER,
        updated_at_utc TEXT NOT NULL
      )
    ''');
    await db.insert(appSettings, {
      'id': 1,
      'theme_mode': 'system',
      'language_mode': 'system',
      'reminders_enabled': 0,
      'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
    });
    await createReminderStates(db);
    await createRoutineDefinitions(db);
    await createDailyReflections(db);
    await createSyncTables(db);
    await createRoutineContentTables(db);
  }

  static Future<void> upgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1 && newVersion >= 1) {
      await create(db);
      return;
    }
    if (oldVersion < 2 && newVersion >= 2) {
      await createReminderStates(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await createRoutineDefinitions(db);
    }
    if (oldVersion < 4 && newVersion >= 4) {
      await createDailyReflections(db);
    }
    if (oldVersion < 5 && newVersion >= 5) {
      await db.execute(
        'ALTER TABLE $appSettings ADD COLUMN onboarding_version INTEGER',
      );
      await db.update(appSettings, {'onboarding_version': 1}, where: 'id = 1');
    }
    if (oldVersion < 6 && newVersion >= 6) {
      await createSyncTables(db);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      await db.execute(
        "ALTER TABLE $appSettings ADD COLUMN language_mode TEXT NOT NULL DEFAULT 'system' CHECK (language_mode IN ('system', 'id', 'en'))",
      );
    }
    if (oldVersion < 8 && newVersion >= 8) {
      await createRoutineContentTables(db);
    }
  }

  static Future<void> createRoutineContentTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $routineContents (
        routine_id TEXT PRIMARY KEY,
        delta_json TEXT NOT NULL,
        plain_text TEXT NOT NULL,
        format_version INTEGER NOT NULL CHECK (format_version = 1),
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES $routineDefinitions(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE $routineAttachments (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type = 'image'),
        local_relative_path TEXT,
        original_file_name TEXT,
        mime_type TEXT NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png')),
        byte_size INTEGER NOT NULL CHECK (byte_size > 0 AND byte_size <= 8388608),
        width INTEGER,
        height INTEGER,
        sort_order INTEGER NOT NULL,
        content_sha256 TEXT,
        storage_path TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        deleted_at_utc TEXT,
        FOREIGN KEY (routine_id) REFERENCES $routineDefinitions(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX routine_attachments_order ON '
      '$routineAttachments(routine_id, deleted_at_utc, sort_order)',
    );
  }

  static Future<void> createSyncTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $syncMetadata (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        device_id TEXT NOT NULL,
        linked_uid TEXT,
        initial_sync_completed INTEGER NOT NULL DEFAULT 0
          CHECK (initial_sync_completed IN (0, 1)),
        last_attempt_at_utc TEXT,
        last_successful_sync_at_utc TEXT,
        last_error_code TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $syncOutbox (
        entity_type TEXT NOT NULL,
        entity_key TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('upsert', 'delete')),
        changed_at_utc TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error_code TEXT,
        PRIMARY KEY (entity_type, entity_key)
      )
    ''');
    await db.execute(
      'CREATE INDEX sync_outbox_changed ON $syncOutbox(changed_at_utc)',
    );
  }

  static Future<void> createDailyReflections(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $dailyReflections (
        date_key TEXT PRIMARY KEY,
        rhythm TEXT NOT NULL CHECK (rhythm IN ('steady', 'mixed', 'heavy')),
        note TEXT,
        recorded_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createReminderStates(DatabaseExecutor db) async {
    await db.execute('''
        CREATE TABLE $routineReminderStates (
          date_key TEXT NOT NULL,
          routine_id TEXT NOT NULL,
          snoozed_until_utc TEXT,
          follow_up_scheduled_at_utc TEXT,
          follow_up_suppressed INTEGER NOT NULL DEFAULT 0
            CHECK (follow_up_suppressed IN (0, 1)),
          last_action TEXT,
          last_action_at_utc TEXT,
          updated_at_utc TEXT NOT NULL,
          PRIMARY KEY (date_key, routine_id)
        )
      ''');
  }

  static Future<void> createRoutineDefinitions(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $routineDefinitions (
        id TEXT PRIMARY KEY,
        origin TEXT NOT NULL CHECK (origin IN ('default', 'custom')),
        template_key TEXT,
        title TEXT NOT NULL,
        description TEXT,
        is_enabled INTEGER NOT NULL CHECK (is_enabled IN (0, 1)),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        schedule_kind TEXT NOT NULL CHECK (schedule_kind IN ('fixed', 'prayer')),
        fixed_time_minutes INTEGER,
        prayer_key TEXT,
        reminder_enabled INTEGER NOT NULL CHECK (reminder_enabled IN (0, 1)),
        priority TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
        sort_order INTEGER NOT NULL,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        CHECK (
          (schedule_kind = 'fixed' AND fixed_time_minutes BETWEEN 0 AND 1439 AND prayer_key IS NULL)
          OR
          (schedule_kind = 'prayer' AND fixed_time_minutes IS NULL AND prayer_key IN ('subuh', 'zuhur', 'asar', 'maghrib', 'isya'))
        ),
        CHECK (
          (origin = 'default' AND template_key IS NOT NULL)
          OR
          (origin = 'custom' AND template_key IS NULL)
        )
      )
    ''');
    await db.execute('''
      CREATE TABLE $routineStepDefinitions (
        routine_id TEXT NOT NULL,
        step_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_required INTEGER NOT NULL CHECK (is_required IN (0, 1)),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        sort_order INTEGER NOT NULL,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        PRIMARY KEY (routine_id, step_id),
        FOREIGN KEY (routine_id) REFERENCES $routineDefinitions(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX routine_definitions_active_order ON '
      '$routineDefinitions(is_archived, is_enabled, sort_order)',
    );
    await db.execute(
      'CREATE INDEX routine_step_definitions_active_order ON '
      '$routineStepDefinitions(routine_id, is_archived, sort_order)',
    );
  }
}
