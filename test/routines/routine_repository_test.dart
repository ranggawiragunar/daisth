import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/data/mappers/routine_definition_mapper.dart';
import 'package:daisth/features/routines/data/repositories/routine_repository_data.dart';
import 'package:daisth/features/routines/data/resolvers/routine_resolver.dart';
import 'package:daisth/features/routines/data/services/routine_sqlite_service.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/prayer_key.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_priority.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/domain/models/routine_step_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/use_cases/ensure_default_routines_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/reset_default_routine_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/save_custom_routine_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';
import '../support/test_persistence.dart';

void main() {
  test(
    'default bootstrap is idempotent and preserves user-owned values',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final repository = _routineRepository(persistence);
      addTearDown(repository.closeChanges);
      final seed = EnsureDefaultRoutinesUseCase(
        repository: repository,
        templates: DefaultRoutineTemplateCatalog.definitions,
      );
      final now = DateTime.utc(2026, 10, 13, 10);

      await seed(now: now);
      await seed(now: now.add(const Duration(days: 1)));
      expect(
        (await repository.getAllManagedRoutines()).map((item) => item.id),
        DefaultRoutineTemplateCatalog.keys,
      );
      expect((await repository.getRoutine('subuh'))!.schedule.kind, 'prayer');
      expect(
        (await repository.getRoutine('subuh'))!.schedule.prayerKey,
        PrayerKey.subuh,
      );

      final dhuha = (await repository.getRoutine('dhuha'))!;
      await repository.saveRoutine(
        dhuha.copyWith(
          isEnabled: false,
          reminderEnabled: false,
          schedule: RoutineSchedule.fixed(8 * 60 + 15),
          updatedAt: now,
        ),
      );
      await seed(now: now.add(const Duration(days: 2)));
      final preserved = (await repository.getRoutine('dhuha'))!;
      expect(preserved.isEnabled, isFalse);
      expect(preserved.reminderEnabled, isFalse);
      expect(preserved.schedule.minutesAfterMidnight, 495);
    },
  );

  test('reset restores factory settings and keeps daily records', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final routines = _routineRepository(persistence);
    addTearDown(routines.closeChanges);
    final now = DateTime.utc(2026, 10, 13, 10);
    await EnsureDefaultRoutinesUseCase(
      repository: routines,
      templates: DefaultRoutineTemplateCatalog.definitions,
    )(now: now);
    final records = persistence.routineRecords;
    final day = CalendarDay(year: 2026, month: 10, day: 13);
    await records.markCompleted(
      routine: RoutineDemoData.dhuha,
      day: day,
      now: now,
    );
    await routines.saveRoutine(
      (await routines.getRoutine('dhuha'))!.copyWith(
        isEnabled: false,
        reminderEnabled: false,
        schedule: RoutineSchedule.fixed(8 * 60 + 15),
        updatedAt: now,
      ),
    );

    await ResetDefaultRoutineUseCase(
      repository: routines,
      templates: DefaultRoutineTemplateCatalog.definitions,
    )('dhuha', now: now.add(const Duration(minutes: 1)));
    final reset = (await routines.getRoutine('dhuha'))!;
    expect(reset.isEnabled, isTrue);
    expect(reset.reminderEnabled, isTrue);
    expect(reset.schedule.minutesAfterMidnight, 420);
    expect(
      (await records.getRoutineRecord(day, 'dhuha'))!.status,
      RoutineStatus.completed,
    );
  });

  test(
    'custom edits preserve IDs and archiving keeps history and definitions',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final routines = _routineRepository(persistence);
      addTearDown(routines.closeChanges);
      final records = persistence.routineRecords;
      final now = DateTime.utc(2026, 10, 13, 10);
      final definition = _custom(now, id: 'custom-stable-test');
      final step = _step(
        now,
        definition.id,
        'step-stable-test',
        'Read',
        true,
        0,
      );
      await routines.saveRoutine(definition, steps: [step]);
      final original = (await routines.getSteps(definition.id)).single;
      await routines.saveRoutine(
        definition.copyWith(title: 'Morning Reading', updatedAt: now),
        steps: [original.copyWith(title: 'Read five pages', updatedAt: now)],
      );
      expect(
        (await routines.getSteps(definition.id)).single.stepId,
        step.stepId,
      );
      expect(
        (await routines.getSteps(definition.id)).single.title,
        'Read five pages',
      );

      final resolved = (await RoutineResolver(
        routines,
      ).resolve(definition.id))!;
      await records.markCompleted(
        routine: resolved.routine,
        day: CalendarDay.fromDateTime(now),
        now: now,
      );
      await routines.archiveCustomRoutine(definition.id, now);
      expect(await routines.getActiveRoutines(), isEmpty);
      expect((await routines.getRoutine(definition.id))!.isArchived, isTrue);
      expect(
        (await records.getRoutineRecord(
          CalendarDay.fromDateTime(now),
          definition.id,
        ))!.status,
        RoutineStatus.completed,
      );
      final row = (await (await persistence.database.open()).query(
        DatabaseSchema.routineStepDefinitions,
        where: 'routine_id = ?',
        whereArgs: [definition.id],
      )).single;
      expect(row['is_archived'], 0);
    },
  );

  test('custom step changes recalculate today completion status', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final routines = _routineRepository(persistence);
    addTearDown(routines.closeChanges);
    final records = persistence.routineRecords;
    final now = DateTime.utc(2026, 10, 13, 10);
    final definition = _custom(now, id: 'custom-recalculate-test');
    final first = _step(now, definition.id, 'step-first', 'Read', true, 0);
    final second = _step(now, definition.id, 'step-second', 'Review', true, 1);
    final save = SaveCustomRoutineUseCase(routines: routines, records: records);
    await save(definition: definition, steps: [first, second], now: now);
    final resolved = (await RoutineResolver(routines).resolve(definition.id))!;
    await SetRoutineStepCompletionUseCase(repository: records)(
      routine: resolved.routine,
      day: CalendarDay.fromDateTime(now),
      stepId: first.stepId,
      isCompleted: true,
      now: now,
    );
    expect(
      (await records.getRoutineRecord(
        CalendarDay.fromDateTime(now),
        definition.id,
      ))!.status,
      RoutineStatus.partial,
    );

    await save(definition: definition, steps: [first], now: now);
    var record = await records.getRoutineRecord(
      CalendarDay.fromDateTime(now),
      definition.id,
    );
    expect(record!.status, RoutineStatus.completed);
    final added = _step(now, definition.id, 'step-added', 'Plan', true, 1);
    await save(definition: definition, steps: [first, added], now: now);
    record = await records.getRoutineRecord(
      CalendarDay.fromDateTime(now),
      definition.id,
    );
    expect(record!.status, RoutineStatus.partial);
    expect(record.completedAt, isNull);
    expect(
      (await records.getStepRecords(
        CalendarDay.fromDateTime(now),
        definition.id,
      )).where((item) => item.stepId == second.stepId),
      hasLength(1),
    );
  });

  test(
    'custom routine validation accepts simple routines and rejects invalid steps',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final routines = _routineRepository(persistence);
      addTearDown(routines.closeChanges);
      final save = SaveCustomRoutineUseCase(
        routines: routines,
        records: persistence.routineRecords,
      );
      final now = DateTime.utc(2026, 10, 13, 10);
      final simple = _custom(now, id: 'custom-simple');
      await save(definition: simple, steps: const [], now: now);
      expect((await routines.getRoutine(simple.id))!.title, simple.title);

      final invalid = _step(
        now,
        simple.id,
        'step-invalid',
        'Optional',
        false,
        0,
      );
      await expectLater(
        save(definition: simple, steps: [invalid], now: now),
        throwsA(isA<RoutineDefinitionValidationException>()),
      );
    },
  );
}

RoutineRepositoryData _routineRepository(TestPersistence persistence) =>
    RoutineRepositoryData(
      service: RoutineSqliteService(persistence.database),
      mapper: RoutineDefinitionMapper(),
    );

RoutineDefinition _custom(DateTime now, {required String id}) =>
    RoutineDefinition(
      id: id,
      origin: RoutineOrigin.custom,
      templateKey: null,
      title: 'Morning Reading',
      description: null,
      isEnabled: true,
      isArchived: false,
      schedule: RoutineSchedule.fixed(6 * 60 + 30),
      reminderEnabled: true,
      priority: RoutinePriority.medium,
      sortOrder: 100,
      createdAt: now,
      updatedAt: now,
    );

RoutineStepDefinition _step(
  DateTime now,
  String routineId,
  String id,
  String title,
  bool required,
  int order,
) => RoutineStepDefinition(
  routineId: routineId,
  stepId: id,
  title: title,
  isRequired: required,
  isArchived: false,
  sortOrder: order,
  createdAt: now,
  updatedAt: now,
);
