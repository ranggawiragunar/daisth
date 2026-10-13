import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../../core/persistence/data/schema/database_schema.dart';

import '../../domain/models/routine_definition.dart';
import '../../domain/models/routine_origin.dart';
import '../../domain/models/routine_step_definition.dart';
import '../../domain/repositories/routine_repository.dart';
import '../mappers/routine_definition_mapper.dart';
import '../services/routine_sqlite_service.dart';
import '../../../sync/data/mappers/firestore_document_ids.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';

class RoutineRepositoryData implements RoutineRepository {
  RoutineRepositoryData({required this.service, required this.mapper});
  final RoutineSqliteService service;
  final RoutineDefinitionMapper mapper;
  final _changes = StreamController<void>.broadcast();
  final _localChanges = StreamController<void>.broadcast();

  Future<void> closeChanges() async {
    await _changes.close();
    await _localChanges.close();
  }

  Stream<void> get localChanges => _localChanges.stream;

  void notifyRemoteChanged() => _changes.add(null);
  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<RoutineDefinition?> getRoutine(String id) async {
    final row = await service.getRoutine(id);
    return row == null ? null : mapper.fromMap(row);
  }

  @override
  Future<List<RoutineDefinition>> getActiveRoutines() async =>
      (await service.getRoutines(includeArchived: false))
          .map(mapper.fromMap)
          .where((definition) => definition.isEnabled)
          .toList(growable: false);

  @override
  Future<List<RoutineDefinition>> getAllManagedRoutines() async =>
      (await service.getRoutines(
        includeArchived: false,
      )).map(mapper.fromMap).toList(growable: false);

  @override
  Future<List<RoutineDefinition>> getAllRoutineDefinitions() async =>
      (await service.getAllRoutines())
          .map(mapper.fromMap)
          .toList(growable: false);

  @override
  Future<CalendarDay?> getEarliestRoutineCreationDay() async {
    final value = await service.getEarliestRoutineCreatedAt();
    return value == null
        ? null
        : CalendarDay.fromDateTime(DateTime.parse(value).toLocal());
  }

  @override
  Future<List<RoutineStepDefinition>> getSteps(String routineId) async =>
      (await service.getSteps(routineId)).map(mapper.stepFromMap).toList();

  @override
  Future<List<RoutineStepDefinition>> getAllStepsIncludingArchived(
    String routineId,
  ) async =>
      (await service.getAllSteps(routineId)).map(mapper.stepFromMap).toList();

  @override
  Future<List<RoutineStepDefinition>>
  getAllStepDefinitionsIncludingArchived() async =>
      (await service.getAllStepDefinitions())
          .map(mapper.stepFromMap)
          .toList(growable: false);

  @override
  Future<void> saveRoutine(
    RoutineDefinition definition, {
    List<RoutineStepDefinition>? steps,
  }) async {
    await service.transaction((transaction) async {
      await transaction.insert(
        DatabaseSchema.routineDefinitions,
        mapper.toMap(definition),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.update(
        DatabaseSchema.routineDefinitions,
        mapper.toMap(definition),
        where: 'id = ?',
        whereArgs: [definition.id],
      );
      await SyncOutboxSqliteHelper.enqueueLocalMutation(
        transaction,
        entityType: 'routineDefinition',
        entityKey: FirestoreDocumentIds.routineDefinition(definition.id),
        operation: 'upsert',
        changedAtUtc: definition.updatedAt,
      );
      if (steps == null) return;
      final current = await transaction.query(
        DatabaseSchema.routineStepDefinitions,
        where: 'routine_id = ? AND is_archived = 0',
        whereArgs: [definition.id],
      );
      final activeIds = steps
          .where((step) => !step.isArchived)
          .map((s) => s.stepId)
          .toSet();
      for (final row in current) {
        final id = row['step_id'] as String;
        if (!activeIds.contains(id)) {
          final archivedStep = mapper
              .stepFromMap(row)
              .copyWith(isArchived: true, updatedAt: definition.updatedAt);
          await transaction.update(
            DatabaseSchema.routineStepDefinitions,
            {
              'is_archived': 1,
              'updated_at_utc': definition.updatedAt.toUtc().toIso8601String(),
            },
            where: 'routine_id = ? AND step_id = ?',
            whereArgs: [definition.id, id],
          );
          await SyncOutboxSqliteHelper.enqueueLocalMutation(
            transaction,
            entityType: 'routineStepDefinition',
            entityKey: FirestoreDocumentIds.routineStepDefinition(
              archivedStep.routineId,
              archivedStep.stepId,
            ),
            operation: 'upsert',
            changedAtUtc: definition.updatedAt,
          );
        }
      }
      for (final step in steps) {
        await transaction.insert(
          DatabaseSchema.routineStepDefinitions,
          mapper.stepToMap(step),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          transaction,
          entityType: 'routineStepDefinition',
          entityKey: FirestoreDocumentIds.routineStepDefinition(
            step.routineId,
            step.stepId,
          ),
          operation: 'upsert',
          changedAtUtc: step.updatedAt,
        );
      }
    });
    _changes.add(null);
    _localChanges.add(null);
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  @override
  Future<void> setEnabled(String id, bool enabled, DateTime now) async {
    final current = await getRoutine(id);
    if (current == null || current.isArchived) return;
    await saveRoutine(current.copyWith(isEnabled: enabled, updatedAt: now));
  }

  @override
  Future<void> archiveCustomRoutine(String id, DateTime now) async {
    final current = await getRoutine(id);
    if (current == null || current.origin != RoutineOrigin.custom) {
      throw StateError('Only custom routines can be archived.');
    }
    await saveRoutine(
      current.copyWith(isEnabled: false, isArchived: true, updatedAt: now),
    );
  }
}
