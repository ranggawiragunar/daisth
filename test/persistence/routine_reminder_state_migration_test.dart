import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reminders/data/mappers/routine_reminder_state_mapper.dart';
import 'package:daisth/features/reminders/data/repositories/routine_reminder_state_repository_data.dart';
import 'package:daisth/features/reminders/data/services/routine_reminder_state_sqlite_service.dart';
import '../support/test_persistence.dart';

void main() {
  test(
    'real v1 database upgrades to v6 and preserves routine/settings data',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('daisth-v1-');
      addTearDown(() => dir.delete(recursive: true));
      final filename = path.join(dir.path, 'daisth.db');
      final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
        filename,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              "CREATE TABLE routine_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, status TEXT NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, not_today_reason TEXT, PRIMARY KEY(date_key, routine_id))",
            );
            await db.execute(
              "CREATE TABLE routine_step_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, step_id TEXT NOT NULL, is_completed INTEGER NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, PRIMARY KEY(date_key, routine_id, step_id))",
            );
            await db.execute(
              "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, theme_mode TEXT NOT NULL, reminders_enabled INTEGER NOT NULL, updated_at_utc TEXT NOT NULL)",
            );
            await db.insert('routine_records', {
              'date_key': '2026-10-13',
              'routine_id': 'zuhur',
              'status': 'partial',
              'recorded_at_utc': '2026-10-13T01:00:00.000Z',
              'updated_at_utc': '2026-10-13T01:00:00.000Z',
            });
            await db.insert('routine_step_records', {
              'date_key': '2026-10-13',
              'routine_id': 'zuhur',
              'step_id': 'zuhur',
              'is_completed': 0,
              'recorded_at_utc': '2026-10-13T01:00:00.000Z',
              'updated_at_utc': '2026-10-13T01:00:00.000Z',
            });
            await db.insert('app_settings', {
              'id': 1,
              'theme_mode': 'dark',
              'reminders_enabled': 1,
              'updated_at_utc': '2026-10-13T01:00:00.000Z',
            });
          },
        ),
      );
      await oldDb.close();
      final service = TestPersistence.createDatabaseServiceAt(filename);
      addTearDown(service.close);
      final db = await service.open();
      expect(
        Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        6,
      );
      expect((await db.query('routine_records')).single['status'], 'partial');
      expect(
        (await db.query('routine_step_records')).single['step_id'],
        'zuhur',
      );
      expect((await db.query('app_settings')).single['theme_mode'], 'dark');
      expect((await db.query('app_settings')).single['onboarding_version'], 1);
      expect(await db.query(DatabaseSchema.routineReminderStates), isEmpty);
      expect(await db.query(DatabaseSchema.routineDefinitions), isEmpty);
      expect(await db.query(DatabaseSchema.routineStepDefinitions), isEmpty);
    },
  );

  test('v2 to v6 migration preserves daily records, actions, and settings', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('daisth-v2-');
    addTearDown(() => dir.delete(recursive: true));
    final filename = path.join(dir.path, 'daisth.db');
    final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
      filename,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            "CREATE TABLE routine_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, status TEXT NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, not_today_reason TEXT, PRIMARY KEY(date_key, routine_id))",
          );
          await db.execute(
            "CREATE TABLE routine_step_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, step_id TEXT NOT NULL, is_completed INTEGER NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, PRIMARY KEY(date_key, routine_id, step_id))",
          );
          await db.execute(
            "CREATE TABLE app_settings (id INTEGER PRIMARY KEY, theme_mode TEXT NOT NULL, reminders_enabled INTEGER NOT NULL, updated_at_utc TEXT NOT NULL)",
          );
          await db.execute(
            "CREATE TABLE routine_reminder_states (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, snoozed_until_utc TEXT, follow_up_scheduled_at_utc TEXT, follow_up_suppressed INTEGER NOT NULL DEFAULT 0, last_action TEXT, last_action_at_utc TEXT, updated_at_utc TEXT NOT NULL, PRIMARY KEY(date_key, routine_id))",
          );
          await db.insert('routine_records', {
            'date_key': '2026-10-13',
            'routine_id': 'zuhur',
            'status': 'completed',
            'completed_at_utc': '2026-10-13T05:00:00.000Z',
            'recorded_at_utc': '2026-10-13T05:00:00.000Z',
            'updated_at_utc': '2026-10-13T05:00:00.000Z',
          });
          await db.insert('routine_step_records', {
            'date_key': '2026-10-13',
            'routine_id': 'zuhur',
            'step_id': 'zuhur',
            'is_completed': 1,
            'completed_at_utc': '2026-10-13T05:00:00.000Z',
            'recorded_at_utc': '2026-10-13T05:00:00.000Z',
            'updated_at_utc': '2026-10-13T05:00:00.000Z',
          });
          await db.insert('app_settings', {
            'id': 1,
            'theme_mode': 'dark',
            'reminders_enabled': 1,
            'updated_at_utc': '2026-10-13T05:00:00.000Z',
          });
          await db.insert('routine_reminder_states', {
            'date_key': '2026-10-13',
            'routine_id': 'zuhur',
            'snoozed_until_utc': null,
            'follow_up_scheduled_at_utc': '2026-10-13T06:00:00.000Z',
            'follow_up_suppressed': 1,
            'last_action': 'snooze',
            'last_action_at_utc': '2026-10-13T05:10:00.000Z',
            'updated_at_utc': '2026-10-13T05:10:00.000Z',
          });
        },
      ),
    );
    await oldDb.close();

    final service = TestPersistence.createDatabaseServiceAt(filename);
    addTearDown(service.close);
    final db = await service.open();
    expect(Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')), 6);
    expect((await db.query('routine_records')).single['status'], 'completed');
    expect((await db.query('routine_step_records')).single['is_completed'], 1);
    expect((await db.query('app_settings')).single['theme_mode'], 'dark');
    expect((await db.query('app_settings')).single['onboarding_version'], 1);
    expect(
      (await db.query('routine_reminder_states')).single['last_action'],
      'snooze',
    );
    expect(await db.query(DatabaseSchema.routineDefinitions), isEmpty);
    expect(await db.query(DatabaseSchema.routineStepDefinitions), isEmpty);
  });

  test(
    'reminder state round trips through SQLite after repository recreation',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repo = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final day = CalendarDay(year: 2026, month: 10, day: 13);
      final now = DateTime.utc(2026, 10, 13, 10);
      await repo.recordSnooze(
        day: day,
        routineId: 'zuhur',
        snoozedUntil: now.add(const Duration(minutes: 10)),
        now: now,
      );
      await repo.recordFollowUpScheduled(
        day: day,
        routineId: 'zuhur',
        scheduledAt: now.add(const Duration(hours: 1)),
        now: now,
      );
      final restored = await RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      ).getState(day, 'zuhur');
      expect(restored?.snoozedUntil, now.add(const Duration(minutes: 10)));
      expect(restored?.followUpScheduledAt, now.add(const Duration(hours: 1)));
      expect(restored?.followUpSuppressed, isTrue);
      expect(restored?.lastAction, 'snooze');
      expect(restored?.lastActionAt, now);
    },
  );
}
