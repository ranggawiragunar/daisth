import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/domain/models/routine_record.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/models/routine_attachment.dart';
import 'package:daisth/features/routines/domain/models/routine_content.dart';
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
    expect(data.keys, isNot(contains('note')));
    expect(data.keys, isNot(contains('rhythm')));
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

  test('routine notes round-trip as bounded Delta content', () {
    final instant = DateTime.utc(2026, 10, 13, 3);
    final original = mapper.routineContent(
      RoutineContent(
        routineId: 'custom/reading',
        serializedDelta: '[{"insert":"Read slowly\\n"}]',
        plainText: 'Read slowly',
        formatVersion: 1,
        createdAt: instant,
        updatedAt: instant,
      ),
      'device-a',
    );
    final data = mapper.toFirestore(original);
    final decoded = mapper.fromFirestore(
      type: SyncEntityType.routineContent,
      documentId: original.id,
      data: data,
    );

    expect(decoded.payload, isA<RoutineContent>());
    expect((decoded.payload! as RoutineContent).plainText, 'Read slowly');
    expect(data, isNot(contains('localRelativePath')));
  });

  test('routine attachment metadata never syncs a local file path', () {
    final instant = DateTime.utc(2026, 10, 13, 3);
    final original = mapper.routineAttachment(
      RoutineAttachment(
        id: 'photo-1',
        routineId: 'custom-reading',
        type: 'image',
        localRelativePath: 'custom-reading/photo-1.jpg',
        originalFileName: 'reading.jpg',
        mimeType: 'image/jpeg',
        byteSize: 4200,
        width: 1200,
        height: 800,
        sortOrder: 0,
        contentSha256: 'abc123',
        storagePath: 'users/user-1/routine-attachments/photo-1/image.jpg',
        createdAt: instant,
        updatedAt: instant,
      ),
      'device-a',
    );
    final data = mapper.toFirestore(original);
    final decoded = mapper.fromFirestore(
      type: SyncEntityType.routineAttachment,
      documentId: original.id,
      data: data,
    );

    expect(data, isNot(contains('localRelativePath')));
    expect((decoded.payload! as RoutineAttachment).localRelativePath, isNull);
    expect(
      (decoded.payload! as RoutineAttachment).storagePath,
      contains('photo-1'),
    );
  });
}
