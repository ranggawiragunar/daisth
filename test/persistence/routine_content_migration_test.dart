import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'v7 to v8 adds content tables without changing routine records',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final db = await persistence.database.open();
      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: CalendarDay(year: 2026, month: 10, day: 13),
        now: DateTime.utc(2026, 10, 13, 3),
      );
      await db.execute('DROP TABLE ${DatabaseSchema.routineContents}');
      await db.execute('DROP TABLE ${DatabaseSchema.routineAttachments}');

      await DatabaseSchema.upgrade(db, 7, 8);

      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseSchema.routineRecords} '
            "WHERE date_key = '2026-10-13' AND routine_id = 'zuhur'",
          ),
        ),
        1,
      );
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(tables.map((row) => row['name']), contains('routine_contents'));
      expect(tables.map((row) => row['name']), contains('routine_attachments'));
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      expect(
        indexes.map((row) => row['name']),
        contains('routine_attachments_order'),
      );
    },
  );
}
