import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/data/mappers/routine_record_mapper.dart';
import 'package:daisth/features/routines/data/repositories/routine_record_repository_data.dart'
    show RoutineRecordRuleException;
import 'package:daisth/features/routines/data/repositories/routine_record_repository_data.dart'
    show RoutineRecordRepositoryData;
import 'package:daisth/features/routines/data/services/routine_record_sqlite_service.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';

import '../support/test_persistence.dart';

void main() {
  final day = CalendarDay(year: 2026, month: 10, day: 13);

  test(
    'round trips partial progress and isolates records by local day',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repository = persistence.routineRecords;
      final first = DateTime.utc(2026, 10, 13, 2);
      final second = DateTime.utc(2026, 10, 13, 3);

      await repository.setStepCompletion(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        stepId: 'hajat',
        isCompleted: true,
        now: first,
      );
      final partial = await repository.getRoutineRecord(day, 'sholat-malam');
      expect(partial?.status, RoutineStatus.partial);
      expect(partial?.recordedAt, first);
      expect(partial?.updatedAt, first);
      expect(
        (await repository.getStepRecords(
          day,
          'sholat-malam',
        )).singleWhere((step) => step.stepId == 'hajat').completedAt,
        first,
      );

      await repository.setStepCompletion(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        stepId: 'witir',
        isCompleted: true,
        now: second,
      );
      expect(
        (await repository.getRoutineRecord(day, 'sholat-malam'))?.recordedAt,
        first,
      );
      expect(
        (await repository.getRoutineRecord(day, 'sholat-malam'))?.updatedAt,
        second,
      );
      expect(
        await repository.getRoutineRecord(
          CalendarDay(year: 2026, month: 10, day: 12),
          'sholat-malam',
        ),
        isNull,
      );

      await persistence.database.close();
      final restartedDatabase = TestPersistence.createDatabaseServiceAt(
        persistence.databasePath,
      );
      addTearDown(restartedDatabase.close);
      final restartedRepository = RoutineRecordRepositoryData(
        service: RoutineRecordSqliteService(restartedDatabase),
        mapper: RoutineRecordMapper(),
      );
      addTearDown(restartedRepository.closeChanges);
      final afterRestart = await restartedRepository.getRoutineRecord(
        day,
        'sholat-malam',
      );
      expect(afterRestart?.status, RoutineStatus.partial);
      expect(
        (await restartedRepository.getStepRecords(
          day,
          'sholat-malam',
        )).where((step) => step.isCompleted).map((step) => step.stepId),
        containsAll(['hajat', 'witir']),
      );
    },
  );

  test('mandatory Not Today is rejected and leaves no rows', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    await expectLater(
      persistence.routineRecords.markNotToday(
        routine: RoutineDemoData.zuhur,
        day: day,
        reason: 'Travel',
        now: DateTime.utc(2026, 10, 13),
      ),
      throwsA(isA<RoutineRecordRuleException>()),
    );
    expect(await persistence.routineRecords.getRecordsForDay(day), isEmpty);
  });

  test(
    'completion timestamp clears on undo and is renewed on re-completion',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repository = persistence.routineRecords;
      final first = DateTime.utc(2026, 10, 13, 1);
      final undone = DateTime.utc(2026, 10, 13, 2);
      final completedAgain = DateTime.utc(2026, 10, 13, 3);

      await repository.markCompleted(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        now: first,
      );
      final initial = await repository.getRoutineRecord(day, 'sholat-malam');
      expect(initial?.status, RoutineStatus.completed);
      expect(initial?.completedAt, first);
      expect(initial?.recordedAt, first);
      expect(initial?.updatedAt, first);

      await repository.setStepCompletion(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        stepId: 'witir',
        isCompleted: false,
        now: undone,
      );
      final partial = await repository.getRoutineRecord(day, 'sholat-malam');
      expect(partial?.status, RoutineStatus.partial);
      expect(partial?.completedAt, isNull);
      expect(partial?.recordedAt, first);
      expect(partial?.updatedAt, undone);

      await repository.markCompleted(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        now: completedAgain,
      );
      final restored = await repository.getRoutineRecord(day, 'sholat-malam');
      expect(restored?.completedAt, completedAgain);
      expect(restored?.recordedAt, first);
      expect(restored?.updatedAt, completedAgain);
    },
  );

  test(
    'optional Dhikr step alone leaves mandatory prayer unrecorded',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);

      await persistence.routineRecords.setStepCompletion(
        routine: RoutineDemoData.zuhur,
        day: day,
        stepId: 'post-prayer-dhikr',
        isCompleted: true,
        now: DateTime.utc(2026, 10, 13, 4),
      );

      expect(
        await persistence.routineRecords.getRoutineRecord(day, 'zuhur'),
        isNull,
      );

      expect(
        (await persistence.routineRecords.getStepRecords(day, 'zuhur'))
            .singleWhere((step) => step.stepId == 'post-prayer-dhikr')
            .isCompleted,
        isTrue,
      );
    },
  );

  test('Not Today preserves the selected optional-routine reason', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);

    await persistence.routineRecords.markNotToday(
      routine: RoutineDemoData.dhuha,
      day: day,
      reason: 'Bepergian',
      now: DateTime.utc(2026, 10, 13, 6),
    );

    final record = await persistence.routineRecords.getRoutineRecord(
      day,
      'dhuha',
    );
    expect(record?.status, RoutineStatus.notToday);
    expect(record?.notTodayReason, 'Bepergian');
  });

  test(
    'Dhuha is complete at its required minimum, optional step is independent',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repository = persistence.routineRecords;
      final now = DateTime.utc(2026, 10, 13, 5);

      await repository.setStepCompletion(
        routine: RoutineDemoData.dhuha,
        day: day,
        stepId: 'dhuha-minimum',
        isCompleted: true,
        now: now,
      );
      expect(
        (await repository.getRoutineRecord(day, 'dhuha'))?.status,
        RoutineStatus.completed,
      );
      await repository.setStepCompletion(
        routine: RoutineDemoData.dhuha,
        day: day,
        stepId: 'dhuha-extra',
        isCompleted: true,
        now: now,
      );
      expect(
        (await repository.getStepRecords(
          day,
          'dhuha',
        )).singleWhere((step) => step.stepId == 'dhuha-extra').isCompleted,
        isTrue,
      );
    },
  );

  test('optional-step progress and routine rows commit atomically', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final db = await persistence.database.open();
    await db.execute('''
      CREATE TRIGGER fail_routine_insert BEFORE INSERT ON ${DatabaseSchema.routineRecords}
      BEGIN SELECT RAISE(ABORT, 'test rollback'); END
    ''');

    await expectLater(
      persistence.routineRecords.setStepCompletion(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        stepId: 'hajat',
        isCompleted: true,
        now: DateTime.utc(2026, 10, 13),
      ),
      throwsA(anything),
    );
    expect(
      await persistence.routineRecords.getStepRecords(day, 'sholat-malam'),
      isEmpty,
    );
    expect(
      await persistence.routineRecords.getRoutineRecord(day, 'sholat-malam'),
      isNull,
    );
  });

  test(
    'history day and range queries preserve selected date identity',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repository = persistence.routineRecords;
      final yesterday = CalendarDay(year: 2026, month: 10, day: 12);
      final today = CalendarDay(year: 2026, month: 10, day: 13);
      final lateEntry = DateTime.utc(2026, 10, 13, 2, 15);

      await repository.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: yesterday,
        now: lateEntry,
      );
      await repository.markCompleted(
        routine: RoutineDemoData.dhuha,
        day: today,
        now: lateEntry,
      );

      final records = await repository.getRecordsBetween(yesterday, today);
      expect(records.map((record) => record.calendarDay.toDateKey()), [
        '2026-10-13',
        '2026-10-12',
      ]);
      expect(await repository.getEarliestRecordDay(), yesterday);
      final steps = await repository.getStepRecordsBetween(yesterday, today);
      expect(steps, isNotEmpty);
      expect(await repository.getStepRecordsForDay(yesterday), hasLength(2));
      expect(
        (await repository.getRoutineRecord(yesterday, 'zuhur'))?.recordedAt,
        lateEntry,
      );
      final row = (await (await persistence.database.open()).query(
        DatabaseSchema.routineRecords,
        where: 'routine_id = ?',
        whereArgs: ['zuhur'],
      )).single;
      expect(row['date_key'], '2026-10-12');
      expect(row['recorded_at_utc'], lateEntry.toIso8601String());
    },
  );

  test(
    'clear removes historical reminder state in the same record operation',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final db = await persistence.database.open();
      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.dhuha,
        day: day,
        now: DateTime.utc(2026, 10, 13),
      );
      await db.insert(DatabaseSchema.routineReminderStates, {
        'date_key': day.toDateKey(),
        'routine_id': 'dhuha',
        'snoozed_until_utc': null,
        'follow_up_scheduled_at_utc': null,
        'follow_up_suppressed': 1,
        'last_action': 'snooze',
        'last_action_at_utc': DateTime.utc(2026, 10, 13).toIso8601String(),
        'updated_at_utc': DateTime.utc(2026, 10, 13).toIso8601String(),
      });

      await persistence.routineRecords.clearRoutineRecord(day, 'dhuha');

      expect(
        await persistence.routineRecords.getRoutineRecord(day, 'dhuha'),
        isNull,
      );
      expect(
        await persistence.routineRecords.getStepRecords(day, 'dhuha'),
        isEmpty,
      );
      expect(await db.query(DatabaseSchema.routineReminderStates), isEmpty);
    },
  );
}
