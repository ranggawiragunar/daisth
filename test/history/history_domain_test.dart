import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/history/domain/models/history_day.dart';
import 'package:daisth/features/history/data/resolvers/history_routine_resolver_data.dart';
import 'package:daisth/features/history/domain/use_cases/build_history_day_use_case.dart';
import 'package:daisth/features/history/domain/use_cases/get_history_range_use_case.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_priority.dart';
import 'package:daisth/features/routines/domain/models/routine.dart';
import 'package:daisth/features/routines/domain/models/routine_requirement.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/domain/models/routine_step.dart';
import 'package:daisth/features/routines/domain/models/routine_step_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';

import '../support/fake_routine_record_repository.dart';
import '../support/fake_routine_repository.dart';

void main() {
  final day = CalendarDay(year: 2026, month: 10, day: 12);
  final now = DateTime.utc(2026, 10, 13, 2, 15);

  test(
    'mandatory prayers are always represented and absent optional routines stay absent',
    () async {
      final records = FakeRoutineRecordRepository();
      final definitions = FakeRoutineRepository(
        definitions: _defaultDefinitions(DateTime.utc(2026, 10, 1)),
      );
      addTearDown(records.close);
      addTearDown(definitions.close);
      final build = BuildHistoryDayUseCase(
        recordRepository: records,
        routineRepository: definitions,
        routineResolver: const HistoryRoutineResolverData(),
      );

      final missing = await build(day);
      expect(
        missing.entries
            .where((entry) => entry.isMandatory)
            .map((entry) => entry.routine.id),
        ['subuh', 'zuhur', 'asar', 'maghrib', 'isya'],
      );
      expect(
        missing.entries.where(
          (entry) =>
              entry.isMandatory &&
              entry.status == HistoryRoutineStatus.unrecorded,
        ),
        hasLength(5),
      );
      expect(
        missing.entries.any((entry) => entry.routine.id == 'dhuha'),
        isFalse,
      );
      expect(
        missing.entries.any((entry) => entry.routine.id == 'penutup-hari'),
        isFalse,
      );

      for (final routine in [
        RoutineDemoData.subuh,
        RoutineDemoData.zuhur,
        RoutineDemoData.asar,
        RoutineDemoData.maghrib,
        RoutineDemoData.isya,
      ]) {
        await records.markCompleted(routine: routine, day: day, now: now);
      }
      final complete = await build(day);
      expect(complete.summary.completed, 5);
      expect(complete.summary.unrecorded, 0);

      await records.markCompleted(
        routine: RoutineDemoData.dhuha,
        day: day,
        now: now,
      );
      final optional = await build(day);
      expect(
        optional.entries
            .singleWhere((entry) => entry.routine.id == 'dhuha')
            .status,
        HistoryRoutineStatus.completed,
      );

      await records.markCompleted(
        routine: RoutineDemoData.penutupHari,
        day: day,
        now: now,
      );
      final withBedtime = await build(day);
      expect(
        withBedtime.entries
            .singleWhere((entry) => entry.routine.id == 'penutup-hari')
            .status,
        HistoryRoutineStatus.completed,
      );
    },
  );

  test(
    'optional Not Today and custom partial states are neutral historical entries',
    () async {
      final routineId = 'custom-routine';
      final definitions = _defaultDefinitions(DateTime.utc(2026, 10, 1))
        ..add(_custom(routineId, DateTime.utc(2026, 10, 1)));
      final steps = [
        _step(routineId, 'read', 'Read', archived: true),
        _step(routineId, 'reflect', 'Reflect', archived: false, sortOrder: 1),
      ];
      final routineRepository = FakeRoutineRepository(
        definitions: definitions,
        steps: steps,
      );
      final records = FakeRoutineRecordRepository();
      addTearDown(records.close);
      addTearDown(routineRepository.close);
      final build = BuildHistoryDayUseCase(
        recordRepository: records,
        routineRepository: routineRepository,
        routineResolver: const HistoryRoutineResolverData(),
      );

      final resolved = (await routineRepository.getAllStepsIncludingArchived(
        routineId,
      ));
      // Record the archived routine directly against its stable definition and step IDs.
      await records.saveResolvedProgress(
        routine: _customRoutine(routineId, steps),
        day: day,
        completedSteps: {'read': true, 'reflect': false},
        status: RoutineStatus.partial,
        notTodayReason: null,
        now: now,
      );
      await records.markNotToday(
        routine: RoutineDemoData.dhuha,
        day: day,
        reason: 'Rest',
        now: now,
      );
      final history = await build(day);
      final item = history.entries.singleWhere(
        (entry) => entry.routine.id == routineId,
      );
      expect(item.status, HistoryRoutineStatus.partial);
      expect(item.isArchived, isFalse);
      expect(item.routine.steps.map((step) => step.title), ['Read', 'Reflect']);
      expect(
        history.entries
            .singleWhere((entry) => entry.routine.id == 'dhuha')
            .status,
        HistoryRoutineStatus.notToday,
      );
      expect(resolved.map((step) => step.stepId), ['read', 'reflect']);
    },
  );

  test(
    'archived routine definitions and archived steps still resolve',
    () async {
      final id = 'archived-custom';
      final definition = _custom(
        id,
        DateTime.utc(2026, 10, 1),
      ).copyWith(isArchived: true);
      final steps = [
        _step(id, 'old-step', 'Old checklist item', archived: true),
      ];
      final routines = FakeRoutineRepository(
        definitions: [
          ..._defaultDefinitions(DateTime.utc(2026, 10, 1)),
          definition,
        ],
        steps: steps,
      );
      final records = FakeRoutineRecordRepository();
      addTearDown(records.close);
      addTearDown(routines.close);
      await records.markCompleted(
        routine: _customRoutine(id, steps),
        day: day,
        now: now,
      );
      final history = await BuildHistoryDayUseCase(
        recordRepository: records,
        routineRepository: routines,
        routineResolver: const HistoryRoutineResolverData(),
      )(day);
      final entry = history.entries.singleWhere(
        (item) => item.routine.id == id,
      );
      expect(entry.isArchived, isTrue);
      expect(entry.routine.title, 'Custom history');
      expect(entry.routine.steps.single.title, 'Old checklist item');
      expect(entry.status, HistoryRoutineStatus.completed);
    },
  );

  test(
    'history ranges start yesterday, cap at 30 days, and stop at local creation boundary',
    () async {
      final definitions = FakeRoutineRepository(
        definitions: _defaultDefinitions(DateTime.utc(2026, 10, 1)),
      );
      final records = FakeRoutineRecordRepository();
      addTearDown(records.close);
      addTearDown(definitions.close);
      final builder = BuildHistoryDayUseCase(
        recordRepository: records,
        routineRepository: definitions,
        routineResolver: const HistoryRoutineResolverData(),
      );
      final range = GetHistoryRangeUseCase(
        recordRepository: records,
        routineRepository: definitions,
        buildDay: builder,
      );
      final first = await range.initial(now: DateTime(2026, 10, 13, 12));
      expect(first.days, hasLength(12));
      expect(first.days.first.day, day);
      expect(first.days.last.day, CalendarDay(year: 2026, month: 10, day: 1));
      expect(first.hasEarlier, isFalse);
      expect(first.days.every((item) => item.summary.unrecorded == 5), isTrue);
    },
  );

  test(
    'load earlier adds an older unique page and never crosses the boundary',
    () async {
      final definitions = FakeRoutineRepository(
        definitions: _defaultDefinitions(DateTime.utc(2026, 8, 1)),
      );
      final records = FakeRoutineRecordRepository();
      addTearDown(records.close);
      addTearDown(definitions.close);
      final builder = BuildHistoryDayUseCase(
        recordRepository: records,
        routineRepository: definitions,
        routineResolver: const HistoryRoutineResolverData(),
      );
      final range = GetHistoryRangeUseCase(
        recordRepository: records,
        routineRepository: definitions,
        buildDay: builder,
      );
      final initial = await range.initial(now: DateTime(2026, 10, 13, 12));
      final earlier = await range.loadBefore(
        initial.days.last.day,
        now: DateTime(2026, 10, 13, 12),
      );
      expect(initial.days, hasLength(30));
      expect(earlier.days, hasLength(30));
      expect(
        earlier.days.first.day.compareTo(initial.days.last.day),
        lessThan(0),
      );
      expect(
        earlier.days
            .map((item) => item.day.toDateKey())
            .toSet()
            .intersection(
              initial.days.map((item) => item.day.toDateKey()).toSet(),
            ),
        isEmpty,
      );
      final finalPage = await range.loadBefore(
        earlier.days.last.day,
        now: DateTime(2026, 10, 13, 12),
      );
      expect(
        finalPage.days.last.day,
        CalendarDay(year: 2026, month: 8, day: 1),
      );
      expect(finalPage.hasEarlier, isFalse);
    },
  );

  test('a deep historical day before the local boundary stays empty', () async {
    final definitions = FakeRoutineRepository(
      definitions: _defaultDefinitions(DateTime.utc(2026, 10, 1)),
    );
    final records = FakeRoutineRecordRepository();
    addTearDown(records.close);
    addTearDown(definitions.close);
    final history = await BuildHistoryDayUseCase(
      recordRepository: records,
      routineRepository: definitions,
      routineResolver: const HistoryRoutineResolverData(),
    )(CalendarDay(year: 2026, month: 9, day: 30));
    expect(history.entries, isEmpty);
    expect(history.summary.isEmpty, isTrue);
  });
}

List<RoutineDefinition> _defaultDefinitions(DateTime created) => [
  for (final id in [
    'sholat-malam',
    'subuh',
    'dhuha',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
    'penutup-hari',
  ])
    RoutineDefinition(
      id: id,
      origin: RoutineOrigin.defaultRoutine,
      templateKey: id,
      title: id,
      isEnabled: true,
      isArchived: false,
      schedule: RoutineSchedule.fixed(300),
      reminderEnabled: true,
      priority: RoutinePriority.medium,
      sortOrder: _defaultOrder(id),
      createdAt: created,
      updatedAt: created,
    ),
];

int _defaultOrder(String id) => [
  'sholat-malam',
  'subuh',
  'dhuha',
  'zuhur',
  'asar',
  'maghrib',
  'isya',
  'penutup-hari',
].indexOf(id);

RoutineDefinition _custom(String id, DateTime created) => RoutineDefinition(
  id: id,
  origin: RoutineOrigin.custom,
  title: 'Custom history',
  isEnabled: false,
  isArchived: false,
  schedule: RoutineSchedule.fixed(400),
  reminderEnabled: false,
  priority: RoutinePriority.low,
  sortOrder: 50,
  createdAt: created,
  updatedAt: created,
);

RoutineStepDefinition _step(
  String routineId,
  String stepId,
  String title, {
  required bool archived,
  int sortOrder = 0,
}) => RoutineStepDefinition(
  routineId: routineId,
  stepId: stepId,
  title: title,
  isRequired: true,
  isArchived: archived,
  sortOrder: sortOrder,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

Routine _customRoutine(String id, List<RoutineStepDefinition> steps) => Routine(
  id: id,
  title: 'Custom history',
  description: '',
  preferredTime: '',
  contextLabel: '',
  isOptional: true,
  steps: [
    for (final step in steps)
      RoutineStep(
        id: step.stepId,
        title: step.title,
        subtitle: '',
        requirement: RoutineRequirement.required,
      ),
  ],
);
