import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/routines/domain/models/routine_record.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/sync/data/mappers/sync_entity_firestore_mapper.dart';
import 'package:daisth/features/sync/data/services/sync_sqlite_service.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'installation device ID remains stable after repository recreation',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final service = SyncSqliteService(persistence.database);

      final first = await service.initialize();
      final second = await service.initialize();

      expect(first.deviceId, isNotEmpty);
      expect(first.deviceId, second.deviceId);
      expect(first.linkedUid, isNull);
      expect(first.initialSyncCompleted, isFalse);
    },
  );

  test(
    'routine writes and clear tombstones are queued atomically after link',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final db = await persistence.database.open();
      await SyncSqliteService(persistence.database).initialize();
      await db.update(DatabaseSchema.syncMetadata, {
        'linked_uid': 'user-1',
      }, where: 'id = 1');
      final day = CalendarDay(year: 2026, month: 10, day: 12);

      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: day,
        now: DateTime.utc(2026, 10, 13, 2),
      );
      final pendingAfterWrite = await db.query(DatabaseSchema.syncOutbox);
      expect(pendingAfterWrite, isNotEmpty);
      expect(
        pendingAfterWrite.every((row) => row['operation'] == 'upsert'),
        isTrue,
      );

      await persistence.routineRecords.clearRoutineRecord(day, 'zuhur');
      final pendingAfterClear = await db.query(DatabaseSchema.syncOutbox);
      expect(pendingAfterClear, isNotEmpty);
      expect(
        pendingAfterClear.every((row) => row['operation'] == 'delete'),
        isTrue,
      );
    },
  );

  test('unlinked local routine writes queue locally without syncing', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final db = await persistence.database.open();
    await SyncSqliteService(persistence.database).initialize();

    await persistence.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: CalendarDay(year: 2026, month: 10, day: 12),
      now: DateTime.utc(2026, 10, 12, 5),
    );

    final pending = await db.query(DatabaseSchema.syncOutbox);
    expect(pending, isNotEmpty);
    expect(pending.every((row) => row['operation'] == 'upsert'), isTrue);
    expect(await db.query(DatabaseSchema.routineRecords), isNotEmpty);
  });

  test(
    'Reflection deletion replaces its pending upsert with a tombstone',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final db = await persistence.database.open();
      await SyncSqliteService(persistence.database).initialize();
      await db.update(DatabaseSchema.syncMetadata, {
        'linked_uid': 'user-1',
      }, where: 'id = 1');
      final day = CalendarDay(year: 2026, month: 10, day: 12);

      await persistence.reflections.saveReflection(
        day: day,
        rhythm: ReflectionRhythm.steady,
        note: 'private note',
        now: DateTime.utc(2026, 10, 12, 12),
      );
      await persistence.reflections.deleteReflection(day);

      final outbox = await db.query(DatabaseSchema.syncOutbox);
      expect(outbox, hasLength(1));
      expect(outbox.single['entity_type'], 'dailyReflection');
      expect(outbox.single['entity_key'], '2026-10-12');
      expect(outbox.single['operation'], 'delete');
      expect(await db.query(DatabaseSchema.dailyReflections), isEmpty);
    },
  );

  test('remote-applied records update SQLite without re-enqueueing', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final service = SyncSqliteService(persistence.database);
    final localState = await service.initialize();
    final now = DateTime.utc(2026, 10, 12, 5);
    final entity = SyncEntityFirestoreMapper().routineRecord(
      RoutineRecord(
        calendarDay: CalendarDay(year: 2026, month: 10, day: 12),
        routineId: 'zuhur',
        status: RoutineStatus.completed,
        completedAt: now,
        recordedAt: now,
        updatedAt: now,
      ),
      'device-remote',
    );

    await service.applyMerge(
      remoteWinners: [entity],
      localWinners: const [],
      nowUtc: now,
    );

    expect(await service.getSnapshot(), hasLength(1));
    expect((await service.getState()).deviceId, localState.deviceId);
    final db = await persistence.database.open();
    expect(await db.query(DatabaseSchema.syncOutbox), isEmpty);
  });

  test('merge transaction preserves a newer concurrent local record', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final db = await persistence.database.open();
    final service = SyncSqliteService(persistence.database);
    await service.initialize();
    await db.update(DatabaseSchema.syncMetadata, {
      'linked_uid': 'user-1',
    }, where: 'id = 1');
    final day = CalendarDay(year: 2026, month: 10, day: 12);
    final localTime = DateTime.utc(2026, 10, 12, 12);
    await persistence.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: day,
      now: localTime,
    );
    final staleCloudEntity = SyncEntityFirestoreMapper().routineRecord(
      RoutineRecord(
        calendarDay: day,
        routineId: 'zuhur',
        status: RoutineStatus.partial,
        recordedAt: DateTime.utc(2026, 10, 12, 9),
        updatedAt: DateTime.utc(2026, 10, 12, 9),
      ),
      'device-cloud',
    );

    final applied = await service.applyMerge(
      remoteWinners: [staleCloudEntity],
      localWinners: const [],
      nowUtc: DateTime.utc(2026, 10, 12, 13),
    );

    expect(applied, isEmpty);
    expect(
      (await persistence.routineRecords.getRoutineRecord(day, 'zuhur'))?.status,
      RoutineStatus.completed,
    );
    expect(await service.getPending(), isNotEmpty);
  });

  test(
    'remote composite step changes recalculate stored routine status',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final db = await persistence.database.open();
      await SyncSqliteService(persistence.database).initialize();
      final day = CalendarDay(year: 2026, month: 10, day: 12);
      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        now: DateTime.utc(2026, 10, 12, 5),
      );
      final step = RoutineDemoData.sholatMalam.steps.first;
      await db.update(
        DatabaseSchema.routineStepRecords,
        {'is_completed': 0, 'completed_at_utc': null},
        where: 'date_key = ? AND routine_id = ? AND step_id = ?',
        whereArgs: [day.toDateKey(), 'sholat-malam', step.id],
      );

      final changed = await persistence.routineRecords.reconcileCompositeStatus(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        now: DateTime.utc(2026, 10, 13, 7),
      );

      expect(changed, isTrue);
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          day,
          'sholat-malam',
        ))?.status,
        RoutineStatus.partial,
      );
    },
  );
}
