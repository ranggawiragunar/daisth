import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import '../support/test_persistence.dart';

void main() {
  test('v4 through v8 preserves local data and marks existing install onboarded', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('daisth-v3-');
    addTearDown(() => directory.delete(recursive: true));
    final filename = path.join(directory.path, 'daisth.db');
    final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
      filename,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE routine_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, status TEXT NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, not_today_reason TEXT, PRIMARY KEY(date_key, routine_id))',
          );
          await db.execute(
            'CREATE TABLE routine_step_records (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, step_id TEXT NOT NULL, is_completed INTEGER NOT NULL, completed_at_utc TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL, PRIMARY KEY(date_key, routine_id, step_id))',
          );
          await db.execute(
            'CREATE TABLE app_settings (id INTEGER PRIMARY KEY, theme_mode TEXT NOT NULL, reminders_enabled INTEGER NOT NULL, updated_at_utc TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE routine_reminder_states (date_key TEXT NOT NULL, routine_id TEXT NOT NULL, snoozed_until_utc TEXT, follow_up_scheduled_at_utc TEXT, follow_up_suppressed INTEGER NOT NULL, last_action TEXT, last_action_at_utc TEXT, updated_at_utc TEXT NOT NULL, PRIMARY KEY(date_key, routine_id))',
          );
          await db.execute(
            'CREATE TABLE routine_definitions (id TEXT PRIMARY KEY, title TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE routine_step_definitions (routine_id TEXT NOT NULL, step_id TEXT NOT NULL, title TEXT NOT NULL, PRIMARY KEY(routine_id, step_id))',
          );
          await db.execute(
            'CREATE TABLE daily_reflections (date_key TEXT PRIMARY KEY, rhythm TEXT NOT NULL, note TEXT, recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL)',
          );
          await db.insert('routine_records', {
            'date_key': '2026-10-12',
            'routine_id': 'zuhur',
            'status': 'completed',
            'completed_at_utc': '2026-10-12T05:00:00.000Z',
            'recorded_at_utc': '2026-10-12T05:00:00.000Z',
            'updated_at_utc': '2026-10-12T05:00:00.000Z',
          });
          await db.insert('routine_step_records', {
            'date_key': '2026-10-12',
            'routine_id': 'zuhur',
            'step_id': 'zuhur',
            'is_completed': 1,
            'completed_at_utc': '2026-10-12T05:00:00.000Z',
            'recorded_at_utc': '2026-10-12T05:00:00.000Z',
            'updated_at_utc': '2026-10-12T05:00:00.000Z',
          });
          await db.insert('app_settings', {
            'id': 1,
            'theme_mode': 'dark',
            'reminders_enabled': 1,
            'updated_at_utc': '2026-10-12T05:00:00.000Z',
          });
          await db.insert('routine_reminder_states', {
            'date_key': '2026-10-12',
            'routine_id': 'zuhur',
            'snoozed_until_utc': null,
            'follow_up_scheduled_at_utc': '2026-10-12T06:00:00.000Z',
            'follow_up_suppressed': 0,
            'last_action': 'open',
            'last_action_at_utc': '2026-10-12T05:30:00.000Z',
            'updated_at_utc': '2026-10-12T05:30:00.000Z',
          });
          await db.insert('routine_definitions', {
            'id': 'zuhur',
            'title': 'Sholat Zuhur',
          });
          await db.insert('routine_step_definitions', {
            'routine_id': 'zuhur',
            'step_id': 'zuhur',
            'title': 'Wajib',
          });
          await db.insert('daily_reflections', {
            'date_key': '2026-10-12',
            'rhythm': 'steady',
            'note': 'Kept locally',
            'recorded_at_utc': '2026-10-12T07:00:00.000Z',
            'updated_at_utc': '2026-10-12T07:00:00.000Z',
          });
        },
      ),
    );
    await oldDb.close();

    final migrated = TestPersistence.createDatabaseServiceAt(filename);
    addTearDown(migrated.close);
    final db = await migrated.open();
    expect(Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')), 8);
    expect(
      (await db.query(DatabaseSchema.dailyReflections)).single['note'],
      'Kept locally',
    );
    expect((await db.query('routine_records')).single['status'], 'completed');
    expect((await db.query('routine_step_records')).single['step_id'], 'zuhur');
    expect(
      (await db.query('routine_definitions')).single['title'],
      'Sholat Zuhur',
    );
    expect(
      (await db.query('routine_step_definitions')).single['title'],
      'Wajib',
    );
    expect(
      (await db.query('routine_reminder_states')).single['last_action'],
      'open',
    );
    expect((await db.query('app_settings')).single['theme_mode'], 'dark');
    expect((await db.query('app_settings')).single['onboarding_version'], 1);
  });
}
