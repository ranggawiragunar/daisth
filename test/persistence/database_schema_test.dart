import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';

import '../support/test_persistence.dart';

void main() {
  test('creates schema v1 tables and system defaults', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);

    final db = await persistence.database.open();
    expect(
      (await db.rawQuery('PRAGMA user_version')).single['user_version'],
      1,
    );
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll([
        DatabaseSchema.routineRecords,
        DatabaseSchema.routineStepRecords,
        DatabaseSchema.appSettings,
      ]),
    );
    expect(await persistence.appSettings.getSettings(), isNotNull);
    expect(
      (await persistence.appSettings.getSettings()).remindersEnabled,
      isFalse,
    );
    final routinePk = await db.rawQuery(
      'PRAGMA table_info(${DatabaseSchema.routineRecords})',
    );
    expect(
      routinePk.where((row) => row['pk'] != 0).map((row) => row['name']),
      containsAll(['date_key', 'routine_id']),
    );
    final stepPk = await db.rawQuery(
      'PRAGMA table_info(${DatabaseSchema.routineStepRecords})',
    );
    expect(
      stepPk.where((row) => row['pk'] != 0).map((row) => row['name']),
      containsAll(['date_key', 'routine_id', 'step_id']),
    );

    final day = CalendarDay(year: 2026, month: 10, day: 13);
    await persistence.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: day,
      now: DateTime.utc(2026, 10, 13, 5),
    );
    await persistence.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: day,
      now: DateTime.utc(2026, 10, 13, 6),
    );
    expect(
      Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseSchema.routineRecords} '
          "WHERE date_key = '2026-10-13' AND routine_id = 'zuhur'",
        ),
      ),
      1,
    );
  });
}
