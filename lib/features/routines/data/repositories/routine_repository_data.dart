import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';

import '../../domain/models/routine_definition.dart';
import '../../domain/models/routine_origin.dart';
import '../../domain/models/routine_step_definition.dart';
import '../../domain/repositories/routine_repository.dart';
import '../mappers/routine_definition_mapper.dart';
import '../services/routine_sqlite_service.dart';

class RoutineRepositoryData implements RoutineRepository {
  RoutineRepositoryData({required this.service, required this.mapper});
  final RoutineSqliteService service;
  final RoutineDefinitionMapper mapper;
  final _changes = StreamController<void>.broadcast();

  Future<void> closeChanges() => _changes.close();
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
  Future<List<RoutineStepDefinition>> getSteps(String routineId) async =>
      (await service.getSteps(routineId)).map(mapper.stepFromMap).toList();

  Future<List<RoutineStepDefinition>> getAllSteps(String routineId) async =>
      (await service.getAllSteps(routineId)).map(mapper.stepFromMap).toList();

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
          await transaction.update(
            DatabaseSchema.routineStepDefinitions,
            {
              'is_archived': 1,
              'updated_at_utc': definition.updatedAt.toUtc().toIso8601String(),
            },
            where: 'routine_id = ? AND step_id = ?',
            whereArgs: [definition.id, id],
          );
        }
      }
      for (final step in steps) {
        await transaction.insert(
          DatabaseSchema.routineStepDefinitions,
          mapper.stepToMap(step),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _changes.add(null);
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
