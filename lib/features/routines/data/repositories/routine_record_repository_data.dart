import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_requirement.dart';
import '../../domain/models/routine_record.dart';
import '../../domain/models/routine_status.dart';
import '../../domain/models/routine_step_record.dart';
import '../../domain/repositories/routine_record_repository.dart';
import '../../domain/use_cases/resolve_routine_status_use_case.dart';
import '../mappers/routine_record_mapper.dart';
import '../models/routine_record_data.dart';
import '../models/routine_step_record_data.dart';
import '../services/routine_record_sqlite_service.dart';

class RoutineRecordRuleException implements Exception {
  const RoutineRecordRuleException(this.message);

  final String message;
}

class RoutineRecordRepositoryData implements RoutineRecordRepository {
  RoutineRecordRepositoryData({required this.service, required this.mapper});

  final RoutineRecordSqliteService service;
  final RoutineRecordMapper mapper;
  final ResolveRoutineStatusUseCase resolveStatus =
      const ResolveRoutineStatusUseCase();
  final StreamController<RoutineRecordChange> _changes =
      StreamController<RoutineRecordChange>.broadcast();

  Future<void> closeChanges() => _changes.close();

  @override
  Stream<RoutineRecordChange> get changes => _changes.stream;

  @override
  Future<RoutineRecord?> getRoutineRecord(
    CalendarDay day,
    String routineId,
  ) async {
    final row = await service.getRoutineRecord(day.toDateKey(), routineId);
    return row == null ? null : mapper.fromData(RoutineRecordData.fromMap(row));
  }

  @override
  Future<List<RoutineStepRecord>> getStepRecords(
    CalendarDay day,
    String routineId,
  ) async => (await service.getStepRecords(day.toDateKey(), routineId))
      .map((row) => mapper.stepFromData(RoutineStepRecordData.fromMap(row)))
      .toList(growable: false);

  @override
  Future<List<RoutineRecord>> getRecordsForDay(CalendarDay day) async =>
      (await service.getRecordsForDay(day.toDateKey()))
          .map((row) => mapper.fromData(RoutineRecordData.fromMap(row)))
          .toList(growable: false);

  @override
  Future<void> setStepCompletion({
    required Routine routine,
    required CalendarDay day,
    required String stepId,
    required bool isCompleted,
    required DateTime now,
  }) async {
    final knownStep = routine.steps.any((step) => step.id == stepId);
    if (!knownStep) {
      throw const RoutineRecordRuleException('Unknown routine step.');
    }
    await service.transaction((transaction) async {
      final rows = await transaction.query(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routine.id],
      );
      final completed = {
        for (final row in rows)
          row['step_id'] as String: row['is_completed'] == 1,
      }..[stepId] = isCompleted;
      await _saveInTransaction(
        transaction,
        routine: routine,
        day: day,
        completedSteps: completed,
        status: _resolveStatus(routine, completed),
        notTodayReason: null,
        now: now,
      );
    });
    _changes.add(RoutineRecordChange(day, routine.id));
  }

  @override
  Future<void> markCompleted({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  }) async => saveResolvedProgress(
    routine: routine,
    day: day,
    completedSteps: {for (final step in routine.steps) step.id: true},
    status: RoutineStatus.completed,
    notTodayReason: null,
    now: now,
  );

  @override
  Future<void> markNotToday({
    required Routine routine,
    required CalendarDay day,
    required String? reason,
    required DateTime now,
  }) async {
    if (!routine.isOptional) {
      throw const RoutineRecordRuleException(
        'Mandatory routines cannot be marked Not Today.',
      );
    }
    await service.transaction((transaction) async {
      final rows = await transaction.query(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routine.id],
      );
      await _saveInTransaction(
        transaction,
        routine: routine,
        day: day,
        completedSteps: {
          for (final row in rows)
            row['step_id'] as String: row['is_completed'] == 1,
        },
        status: RoutineStatus.notToday,
        notTodayReason: reason,
        now: now,
      );
    });
    _changes.add(RoutineRecordChange(day, routine.id));
  }

  @override
  Future<void> markRequiredCompleted({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  }) async {
    await service.transaction((transaction) async {
      final rows = await transaction.query(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routine.id],
      );
      final completed = {
        for (final row in rows)
          row['step_id'] as String: row['is_completed'] == 1,
        for (final step in routine.steps)
          if (step.requirement == RoutineRequirement.required) step.id: true,
      };
      await _saveInTransaction(
        transaction,
        routine: routine,
        day: day,
        completedSteps: completed,
        status: _resolveStatus(routine, completed),
        notTodayReason: null,
        now: now,
      );
    });
    _changes.add(RoutineRecordChange(day, routine.id));
  }

  @override
  Future<void> clearRoutineRecord(CalendarDay day, String routineId) async {
    await service.transaction((transaction) async {
      await transaction.delete(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routineId],
      );
      await transaction.delete(
        DatabaseSchema.routineRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routineId],
      );
    });
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
      throw const RoutineRecordRuleException(
        'Mandatory routines cannot be marked Not Today.',
      );
    }
    await service.transaction(
      (transaction) => _saveInTransaction(
        transaction,
        routine: routine,
        day: day,
        completedSteps: completedSteps,
        status: status,
        notTodayReason: notTodayReason,
        now: now,
      ),
    );
    _changes.add(RoutineRecordChange(day, routine.id));
  }

  Future<void> _saveInTransaction(
    Transaction transaction, {
    required Routine routine,
    required CalendarDay day,
    required Map<String, bool> completedSteps,
    required RoutineStatus status,
    required String? notTodayReason,
    required DateTime now,
  }) async {
    if (status == RoutineStatus.notToday && !routine.isOptional) {
      throw const RoutineRecordRuleException(
        'Mandatory routines cannot be marked Not Today.',
      );
    }
    final dateKey = day.toDateKey();
    final instantText = now.toUtc().toIso8601String();
    for (final step in routine.steps) {
      final isCompleted = completedSteps[step.id] ?? false;
      final oldRows = await transaction.query(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ? AND step_id = ?',
        whereArgs: [dateKey, routine.id, step.id],
        limit: 1,
      );
      final old = oldRows.firstOrNull;
      final oldCompleted = old?['is_completed'] == 1;
      final changed = old == null || oldCompleted != isCompleted;
      final row = RoutineStepRecordData(
        dateKey: dateKey,
        routineId: routine.id,
        stepId: step.id,
        isCompleted: isCompleted,
        completedAtUtc: !isCompleted
            ? null
            : oldCompleted
            ? old!['completed_at_utc'] as String?
            : instantText,
        recordedAtUtc: old?['recorded_at_utc'] as String? ?? instantText,
        updatedAtUtc: changed ? instantText : old['updated_at_utc'] as String,
      );
      await transaction.insert(
        DatabaseSchema.routineStepRecords,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final oldRows = await transaction.query(
      DatabaseSchema.routineRecords,
      where: 'date_key = ? AND routine_id = ?',
      whereArgs: [dateKey, routine.id],
      limit: 1,
    );
    final old = oldRows.firstOrNull;
    if (status == RoutineStatus.pending) {
      await transaction.delete(
        DatabaseSchema.routineRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [dateKey, routine.id],
      );
    } else {
      String? completedAt;
      if (status == RoutineStatus.completed) {
        completedAt = old?['status'] == RoutineStatus.completed.name
            ? (old?['completed_at_utc'] as String? ?? instantText)
            : instantText;
      }
      final row = RoutineRecordData(
        dateKey: dateKey,
        routineId: routine.id,
        status: status.name,
        completedAtUtc: completedAt,
        recordedAtUtc: old?['recorded_at_utc'] as String? ?? instantText,
        updatedAtUtc: instantText,
        notTodayReason: status == RoutineStatus.notToday
            ? notTodayReason
            : null,
      );
      await transaction.insert(
        DatabaseSchema.routineRecords,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  RoutineStatus _resolveStatus(Routine routine, Map<String, bool> steps) {
    return resolveStatus(
      routine: routine,
      completedStepIds: {
        for (final entry in steps.entries)
          if (entry.value) entry.key,
      },
    );
  }
}
