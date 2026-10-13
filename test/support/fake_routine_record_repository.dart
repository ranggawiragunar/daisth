import 'dart:async';

import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/domain/models/routine.dart';
import 'package:daisth/features/routines/domain/models/routine_requirement.dart';
import 'package:daisth/features/routines/domain/models/routine_record.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/models/routine_step_record.dart';
import 'package:daisth/features/routines/domain/repositories/routine_record_repository.dart';
import 'package:daisth/features/routines/domain/use_cases/resolve_routine_status_use_case.dart';

class FakeRoutineRecordRepository implements RoutineRecordRepository {
  final Map<String, RoutineRecord> _records = {};
  final Map<String, RoutineStepRecord> _steps = {};
  final _changes = StreamController<RoutineRecordChange>.broadcast();
  final _resolveStatus = const ResolveRoutineStatusUseCase();

  String _routineKey(CalendarDay day, String routineId) =>
      '${day.toDateKey()}:$routineId';

  String _stepKey(CalendarDay day, String routineId, String stepId) =>
      '${_routineKey(day, routineId)}:$stepId';

  @override
  Stream<RoutineRecordChange> get changes => _changes.stream;

  @override
  Future<RoutineRecord?> getRoutineRecord(
    CalendarDay day,
    String routineId,
  ) async => _records[_routineKey(day, routineId)];

  @override
  Future<List<RoutineStepRecord>> getStepRecords(
    CalendarDay day,
    String routineId,
  ) async => [
    for (final step in _steps.values)
      if (step.calendarDay == day && step.routineId == routineId) step,
  ];

  @override
  Future<List<RoutineRecord>> getRecordsForDay(CalendarDay day) async => [
    for (final record in _records.values)
      if (record.calendarDay == day) record,
  ];

  @override
  Future<void> setStepCompletion({
    required Routine routine,
    required CalendarDay day,
    required String stepId,
    required bool isCompleted,
    required DateTime now,
  }) async {
    final completed = {
      for (final step in await getStepRecords(day, routine.id))
        step.stepId: step.isCompleted,
    }..[stepId] = isCompleted;
    await saveResolvedProgress(
      routine: routine,
      day: day,
      completedSteps: completed,
      status: _status(routine, completed),
      notTodayReason: null,
      now: now,
    );
  }

  @override
  Future<void> markCompleted({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  }) => saveResolvedProgress(
    routine: routine,
    day: day,
    completedSteps: {for (final step in routine.steps) step.id: true},
    status: RoutineStatus.completed,
    notTodayReason: null,
    now: now,
  );

  @override
  Future<void> markRequiredCompleted({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  }) async {
    final completed = {
      for (final step in await getStepRecords(day, routine.id))
        step.stepId: step.isCompleted,
      for (final step in routine.steps)
        if (step.requirement == RoutineRequirement.required) step.id: true,
    };
    await saveResolvedProgress(
      routine: routine,
      day: day,
      completedSteps: completed,
      status: _status(routine, completed),
      notTodayReason: null,
      now: now,
    );
  }

  @override
  Future<void> markNotToday({
    required Routine routine,
    required CalendarDay day,
    required String? reason,
    required DateTime now,
  }) async {
    if (!routine.isOptional) throw StateError('Routine is mandatory.');
    await saveResolvedProgress(
      routine: routine,
      day: day,
      completedSteps: {
        for (final step in await getStepRecords(day, routine.id))
          step.stepId: step.isCompleted,
      },
      status: RoutineStatus.notToday,
      notTodayReason: reason,
      now: now,
    );
  }

  @override
  Future<void> clearRoutineRecord(CalendarDay day, String routineId) async {
    _records.remove(_routineKey(day, routineId));
    _steps.removeWhere(
      (key, step) => step.calendarDay == day && step.routineId == routineId,
    );
    _changes.add(RoutineRecordChange(day, routineId));
  }

  @override
  Future<void> saveResolvedProgress({
    required Routine routine,
    required CalendarDay day,
    required Map<String, bool> completedSteps,
    required RoutineStatus status,
    required String? notTodayReason,
    required DateTime now,
  }) async {
    if (status == RoutineStatus.notToday && !routine.isOptional) {
      throw StateError('Routine is mandatory.');
    }
    final instant = now.toUtc();
    for (final step in routine.steps) {
      final key = _stepKey(day, routine.id, step.id);
      final old = _steps[key];
      final completed = completedSteps[step.id] ?? false;
      _steps[key] = RoutineStepRecord(
        calendarDay: day,
        routineId: routine.id,
        stepId: step.id,
        isCompleted: completed,
        completedAt: !completed
            ? null
            : old?.isCompleted == true
            ? old?.completedAt
            : instant,
        recordedAt: old?.recordedAt ?? instant,
        updatedAt: old?.isCompleted == completed ? old!.updatedAt : instant,
      );
    }
    final key = _routineKey(day, routine.id);
    final old = _records[key];
    if (status == RoutineStatus.pending) {
      _records.remove(key);
    } else {
      _records[key] = RoutineRecord(
        calendarDay: day,
        routineId: routine.id,
        status: status,
        completedAt: status != RoutineStatus.completed
            ? null
            : old?.status == RoutineStatus.completed
            ? old?.completedAt ?? instant
            : instant,
        recordedAt: old?.recordedAt ?? instant,
        updatedAt: instant,
        notTodayReason: status == RoutineStatus.notToday
            ? notTodayReason
            : null,
      );
    }
    _changes.add(RoutineRecordChange(day, routine.id));
  }

  RoutineStatus _status(Routine routine, Map<String, bool> steps) =>
      _resolveStatus(
        routine: routine,
        completedStepIds: {
          for (final entry in steps.entries)
            if (entry.value) entry.key,
        },
      );
}
