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
import '../../../sync/data/mappers/firestore_document_ids.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';

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
  void notifyRemoteChanged(CalendarDay day, String routineId) =>
      _changes.add(RoutineRecordChange(day, routineId, isRemoteSync: true));

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

  Future<List<RoutineRecord>> getRecordsForRoutine(String routineId) async =>
      (await service.getRecordsForRoutine(routineId))
          .map((row) => mapper.fromData(RoutineRecordData.fromMap(row)))
          .toList(growable: false);

  @override
  Future<List<RoutineRecord>> getRecordsBetween(
    CalendarDay startDay,
    CalendarDay endDay,
  ) async => (await service.getRecordsBetween(
    startDay.toDateKey(),
    endDay.toDateKey(),
  )).map((row) => mapper.fromData(RoutineRecordData.fromMap(row))).toList();

  @override
  Future<List<RoutineStepRecord>> getStepRecordsForDay(CalendarDay day) async =>
      (await service.getStepRecordsForDay(day.toDateKey()))
          .map((row) => mapper.stepFromData(RoutineStepRecordData.fromMap(row)))
          .toList(growable: false);

  @override
  Future<List<RoutineStepRecord>> getStepRecordsBetween(
    CalendarDay startDay,
    CalendarDay endDay,
  ) async =>
      (await service.getStepRecordsBetween(
            startDay.toDateKey(),
            endDay.toDateKey(),
          ))
          .map((row) => mapper.stepFromData(RoutineStepRecordData.fromMap(row)))
          .toList();

  @override
  Future<CalendarDay?> getEarliestRecordDay() async {
    final value = await service.getEarliestRecordDateKey();
    if (value == null) return null;
    final parts = value.split('-').map(int.parse).toList(growable: false);
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2]);
  }

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
        status: routine.steps.isEmpty
            ? RoutineStatus.completed
            : _resolveStatus(routine, completed),
        notTodayReason: null,
        now: now,
      );
    });
    _changes.add(RoutineRecordChange(day, routine.id));
    SyncOutboxSqliteHelper.notifyLocalMutation();
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
    SyncOutboxSqliteHelper.notifyLocalMutation();
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
        status: routine.steps.isEmpty
            ? RoutineStatus.completed
            : _resolveStatus(routine, completed),
        notTodayReason: null,
        now: now,
      );
    });
    _changes.add(RoutineRecordChange(day, routine.id));
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  @override
  Future<void> clearRoutineRecord(CalendarDay day, String routineId) async {
    await service.transaction((transaction) async {
      final existingRoutine = await transaction.query(
        DatabaseSchema.routineRecords,
        columns: ['routine_id'],
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routineId],
        limit: 1,
      );
      final existingSteps = await transaction.query(
        DatabaseSchema.routineStepRecords,
        columns: ['step_id'],
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routineId],
      );
      final changedAt = DateTime.now().toUtc();
      final dateKey = day.toDateKey();
      for (final row in existingSteps) {
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineStepRecord',
          entityKey: FirestoreDocumentIds.routineStepRecord(
            dateKey,
            routineId,
            row['step_id'] as String,
          ),
          operation: 'delete',
          changedAtUtc: changedAt,
        );
      }
      if (existingRoutine.isNotEmpty) {
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineRecord',
          entityKey: FirestoreDocumentIds.routineRecord(dateKey, routineId),
          operation: 'delete',
          changedAtUtc: changedAt,
        );
      }
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
      await transaction.delete(
        DatabaseSchema.routineReminderStates,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routineId],
      );
    });
    _changes.add(RoutineRecordChange(day, routineId));
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  Future<bool> reconcileCompositeStatus({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  }) async {
    if (routine.steps.isEmpty) return false;
    var changed = false;
    await service.transaction((transaction) async {
      final recordRows = await transaction.query(
        DatabaseSchema.routineRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routine.id],
        limit: 1,
      );
      final old = recordRows.firstOrNull;
      if (old == null || old['status'] == RoutineStatus.notToday.name) return;
      final stepRows = await transaction.query(
        DatabaseSchema.routineStepRecords,
        where: 'date_key = ? AND routine_id = ?',
        whereArgs: [day.toDateKey(), routine.id],
      );
      final completed = {
        for (final row in stepRows)
          if (row['is_completed'] == 1) row['step_id'] as String,
      };
      final resolved = resolveStatus(
        routine: routine,
        completedStepIds: completed,
      );
      if (resolved.name == old['status']) return;
      final dateKey = day.toDateKey();
      if (resolved == RoutineStatus.pending) {
        await transaction.delete(
          DatabaseSchema.routineRecords,
          where: 'date_key = ? AND routine_id = ?',
          whereArgs: [dateKey, routine.id],
        );
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineRecord',
          entityKey: FirestoreDocumentIds.routineRecord(dateKey, routine.id),
          operation: 'delete',
          changedAtUtc: now,
        );
      } else {
        DateTime? completedAt;
        if (resolved == RoutineStatus.completed) {
          if (old['status'] == RoutineStatus.completed.name) {
            final value = old['completed_at_utc'] as String?;
            completedAt = value == null ? null : DateTime.parse(value).toUtc();
          } else {
            final requiredIds = routine.steps
                .where((step) => step.isRequired)
                .map((step) => step.id)
                .toSet();
            final timestamps = stepRows
                .where(
                  (row) =>
                      requiredIds.contains(row['step_id']) &&
                      row['is_completed'] == 1 &&
                      row['completed_at_utc'] is String,
                )
                .map(
                  (row) =>
                      DateTime.parse(row['completed_at_utc'] as String).toUtc(),
                )
                .toList();
            completedAt = timestamps.isEmpty
                ? now.toUtc()
                : timestamps.reduce((a, b) => a.isAfter(b) ? a : b);
          }
        }
        final row = RoutineRecordData(
          dateKey: dateKey,
          routineId: routine.id,
          status: resolved.name,
          completedAtUtc: completedAt?.toIso8601String(),
          recordedAtUtc: old['recorded_at_utc'] as String,
          updatedAtUtc: now.toUtc().toIso8601String(),
        );
        await transaction.insert(
          DatabaseSchema.routineRecords,
          row.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineRecord',
          entityKey: FirestoreDocumentIds.routineRecord(dateKey, routine.id),
          operation: 'upsert',
          changedAtUtc: now,
        );
      }
      changed = true;
    });
    if (changed) {
      _changes.add(RoutineRecordChange(day, routine.id, isRemoteSync: true));
      SyncOutboxSqliteHelper.notifyLocalMutation();
    }
    return changed;
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
    SyncOutboxSqliteHelper.notifyLocalMutation();
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
      if (changed) {
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineStepRecord',
          entityKey: FirestoreDocumentIds.routineStepRecord(
            dateKey,
            routine.id,
            step.id,
          ),
          operation: 'upsert',
          changedAtUtc: DateTime.parse(row.updatedAtUtc),
        );
      }
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
      if (old != null) {
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineRecord',
          entityKey: FirestoreDocumentIds.routineRecord(dateKey, routine.id),
          operation: 'delete',
          changedAtUtc: now,
        );
      }
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
      await SyncOutboxSqliteHelper.enqueueLocalMutation(
        transaction,
        entityType: 'routineRecord',
        entityKey: FirestoreDocumentIds.routineRecord(dateKey, routine.id),
        operation: 'upsert',
        changedAtUtc: now,
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
