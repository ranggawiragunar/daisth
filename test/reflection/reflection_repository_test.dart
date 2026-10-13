import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reflection/data/mappers/reflection_mapper.dart';
import 'package:daisth/features/reflection/data/repositories/reflection_repository_data.dart';
import 'package:daisth/features/reflection/data/services/reflection_sqlite_service.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/reflection/domain/use_cases/save_daily_reflection_use_case.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import '../support/test_persistence.dart';

void main() {
  test('save, reload, edit and delete preserve reflection semantics', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final day = CalendarDay(year: 2026, month: 10, day: 12);
    final first = DateTime.utc(2026, 10, 13, 2);
    final second = DateTime.utc(2026, 10, 13, 3);
    final useCase = SaveDailyReflectionUseCase(persistence.reflections);

    final created = await useCase(
      day: day,
      rhythm: ReflectionRhythm.mixed,
      note: '  \n  ',
      now: first,
    );
    expect(created.day, day);
    expect(created.rhythm, ReflectionRhythm.mixed);
    expect(created.note, isNull);
    expect(created.recordedAt, first);
    expect(created.updatedAt, first);

    final restored = await ReflectionRepositoryData(
      service: ReflectionSqliteService(persistence.database),
      mapper: ReflectionMapper(),
    ).getReflection(day);
    expect(restored?.rhythm, ReflectionRhythm.mixed);
    expect(restored?.recordedAt, first);

    final edited = await useCase(
      day: day,
      rhythm: ReflectionRhythm.heavy,
      note: '  line one\nline two  ',
      now: second,
    );
    expect(edited.rhythm, ReflectionRhythm.heavy);
    expect(edited.note, 'line one\nline two');
    expect(edited.recordedAt, first);
    expect(edited.updatedAt, second);

    await persistence.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: day,
      now: first,
    );
    expect(await persistence.reflections.deleteReflection(day), isTrue);
    expect(await persistence.reflections.getReflection(day), isNull);
    expect(
      await persistence.routineRecords.getRoutineRecord(day, 'zuhur'),
      isNotNull,
    );
  });

  test('mapper rejects unknown persisted rhythm values', () {
    expect(
      () => ReflectionMapper().fromData({
        'date_key': '2026-10-12',
        'rhythm': 'unknown',
        'note': null,
        'recorded_at_utc': '2026-10-13T02:00:00.000Z',
        'updated_at_utc': '2026-10-13T02:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
