import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import '../support/test_persistence.dart';

void main() {
  test('v5 to v6 adds sync tables and preserves existing rows', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('daisth-v5-');
    addTearDown(() => directory.delete(recursive: true));
    final filename = path.join(directory.path, 'daisth.db');
    final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
      filename,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE routine_records (
              date_key TEXT NOT NULL, routine_id TEXT NOT NULL,
              status TEXT NOT NULL, completed_at_utc TEXT,
              recorded_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL,
              not_today_reason TEXT, PRIMARY KEY(date_key, routine_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE app_settings (
              id INTEGER PRIMARY KEY, theme_mode TEXT NOT NULL,
              reminders_enabled INTEGER NOT NULL,
              onboarding_version INTEGER, updated_at_utc TEXT NOT NULL
            )
          ''');
          await db.insert('routine_records', {
            'date_key': '2026-10-12',
            'routine_id': 'zuhur',
            'status': 'completed',
            'recorded_at_utc': '2026-10-12T05:00:00.000Z',
            'updated_at_utc': '2026-10-12T05:00:00.000Z',
          });
          await db.insert('app_settings', {
            'id': 1,
            'theme_mode': 'dark',
            'reminders_enabled': 1,
            'onboarding_version': 1,
            'updated_at_utc': '2026-10-12T05:00:00.000Z',
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
    expect((await db.query('app_settings')).single['theme_mode'], 'dark');
    expect(await db.query(DatabaseSchema.syncMetadata), isEmpty);
    expect(await db.query(DatabaseSchema.syncOutbox), isEmpty);
  });
}
