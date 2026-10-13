import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/domain/models/routine_record.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/sync/data/mappers/firestore_document_ids.dart';
import 'package:daisth/features/sync/data/mappers/sync_entity_firestore_mapper.dart';
import 'package:daisth/features/sync/domain/models/sync_entity.dart';

void main() {
  final mapper = SyncEntityFirestoreMapper();

  test('routine record round trips through the Firestore envelope', () {
    final instant = DateTime.utc(2026, 10, 13, 3, 10);
    final original = mapper.routineRecord(
      RoutineRecord(
        calendarDay: CalendarDay(year: 2026, month: 10, day: 13),
        routineId: 'zuhur',
        status: RoutineStatus.completed,
        completedAt: instant,
        recordedAt: instant,
        updatedAt: instant,
      ),
      'device-a',
    );
    final decoded = mapper.fromFirestore(
      type: SyncEntityType.routineRecord,
      documentId: original.id,
      data: mapper.toFirestore(original),
    );

    expect(decoded.id, '2026-10-13__zuhur');
    expect(decoded.sourceDeviceId, 'device-a');
    expect(decoded.payload, isA<RoutineRecord>());
    expect(
      (decoded.payload! as RoutineRecord).calendarDay.toDateKey(),
      '2026-10-13',
    );
  });

  test('tombstones encode without a domain payload', () {
    final instant = DateTime.utc(2026, 10, 13);
    final tombstone = SyncEntity(
      type: SyncEntityType.dailyReflection,
      id: '2026-10-13',
      updatedAtUtc: instant,
      deletedAtUtc: instant,
      sourceDeviceId: 'device-a',
      payload: null,
      isDeleted: true,
    );
    final data = mapper.toFirestore(tombstone);

    expect(data['isDeleted'], isTrue);
    expect(data['deletedAtUtc'], isA<Timestamp>());
    expect(data['schemaVersion'], 1);
  });

  test('stable composite IDs escape separators inside routine IDs', () {
    final id = FirestoreDocumentIds.routineStepRecord(
      '2026-10-13',
      'custom_routine',
      'step__one',
    );
    expect(FirestoreDocumentIds.splitTriple(id), (
      '2026-10-13',
      'custom_routine',
      'step__one',
    ));
  });
}
