import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/data/resolvers/routine_resolver.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';
import '../support/fake_routine_repository.dart';
import '../support/test_persistence.dart';

void main() {
  test('default capability has stable seven-step bedtime checklist', () {
    final routine = RoutineDemoData.byId('penutup-hari')!;
    expect(routine.steps.map((step) => step.id), [
      'wudu',
      'ayat-kursi',
      'al-ikhlas',
      'al-falaq',
      'an-nas',
      'al-baqarah-285-286',
      'doa-sebelum-tidur',
    ]);
    expect(routine.steps.where((step) => step.isRequired), hasLength(6));
    expect(routine.steps.where((step) => !step.isRequired).single.id, 'wudu');
  });

  test('resolver uses the persisted Penutup Hari preferred time', () async {
    final created = DateTime.utc(2026, 10, 1);
    final factory = DefaultRoutineTemplateCatalog.definitions(
      created,
    ).singleWhere((routine) => routine.id == 'penutup-hari');
    final persisted = factory.copyWith(
      schedule: const FixedRoutineSchedule(22 * 60 + 15),
      isEnabled: false,
      reminderEnabled: false,
    );
    final repository = FakeRoutineRepository(definitions: [persisted]);
    addTearDown(repository.close);

    final resolved = await RoutineResolver(repository).resolve('penutup-hari');
    expect(resolved!.definition.isEnabled, isFalse);
    expect(resolved.definition.reminderEnabled, isFalse);
    expect(resolved.routine.preferredTime, '22:15');
    expect(resolved.routine.steps, hasLength(7));
  });

  test(
    'completion preserves optional Wudu and partial changes recalculate',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      const day = CalendarDay(year: 2026, month: 10, day: 12);
      final routine = RoutineDemoData.penutupHari;
      final setStep = SetRoutineStepCompletionUseCase(
        repository: persistence.routineRecords,
      );
      final now = DateTime.utc(2026, 10, 13, 1);

      await setStep(
        routine: routine,
        day: day,
        stepId: 'wudu',
        isCompleted: true,
        now: now,
      );
      expect(
        await persistence.routineRecords.getRoutineRecord(day, routine.id),
        isNull,
      );
      expect(
        (await persistence.routineRecords.getStepRecords(
          day,
          routine.id,
        )).singleWhere((step) => step.stepId == 'wudu').isCompleted,
        isTrue,
      );

      for (final step
          in routine.steps.where((step) => step.isRequired).take(2)) {
        await setStep(
          routine: routine,
          day: day,
          stepId: step.id,
          isCompleted: true,
          now: now,
        );
      }
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          day,
          routine.id,
        ))!.status,
        RoutineStatus.partial,
      );

      await MarkRoutineCompleteUseCase(
        repository: persistence.routineRecords,
        resolveStatus: const ResolveRoutineStatusUseCase(),
      )(routine: routine, day: day, now: now, includeOptional: false);
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          day,
          routine.id,
        ))!.status,
        RoutineStatus.completed,
      );
      final records = await persistence.routineRecords.getStepRecords(
        day,
        routine.id,
      );
      expect(records.where((step) => step.isCompleted), hasLength(7));
      expect(
        records.singleWhere((step) => step.stepId == 'wudu').isCompleted,
        isTrue,
      );

      await setStep(
        routine: routine,
        day: day,
        stepId: 'an-nas',
        isCompleted: false,
        now: now.add(const Duration(minutes: 2)),
      );
      final record = await persistence.routineRecords.getRoutineRecord(
        day,
        routine.id,
      );
      expect(record!.status, RoutineStatus.partial);
      expect(record.completedAt, isNull);
    },
  );

  test('six required readings complete the routine without Wudu', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    const day = CalendarDay(year: 2026, month: 10, day: 12);
    final routine = RoutineDemoData.penutupHari;

    await MarkRoutineCompleteUseCase(
      repository: persistence.routineRecords,
      resolveStatus: const ResolveRoutineStatusUseCase(),
    )(
      routine: routine,
      day: day,
      now: DateTime.utc(2026, 10, 13, 1),
      includeOptional: false,
    );

    expect(
      (await persistence.routineRecords.getRoutineRecord(
        day,
        routine.id,
      ))!.status,
      RoutineStatus.completed,
    );
    final steps = await persistence.routineRecords.getStepRecords(
      day,
      routine.id,
    );
    expect(steps.where((step) => step.isCompleted), hasLength(6));
    expect(
      steps.singleWhere((step) => step.stepId == 'wudu').isCompleted,
      isFalse,
    );
  });
}
