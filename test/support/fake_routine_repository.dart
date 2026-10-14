import 'dart:async';

import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_step_definition.dart';
import 'package:daisth/features/routines/domain/repositories/routine_repository.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';

class FakeRoutineRepository implements RoutineRepository {
  FakeRoutineRepository({
    List<RoutineDefinition>? definitions,
    List<RoutineStepDefinition> steps = const [],
  }) {
    for (final definition
        in definitions ??
            DefaultRoutineTemplateCatalog.definitions(DateTime.now())) {
      _definitions[definition.id] = definition;
    }
    for (final step in steps) {
      _steps['${step.routineId}:${step.stepId}'] = step;
    }
  }

  final Map<String, RoutineDefinition> _definitions = {};
  final Map<String, RoutineStepDefinition> _steps = {};
  final _changes = StreamController<void>.broadcast();

  Future<void> close() => _changes.close();
  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<RoutineDefinition?> getRoutine(String id) async => _definitions[id];

  @override
  Future<List<RoutineDefinition>> getActiveRoutines() async =>
      (await getAllManagedRoutines())
          .where((item) => item.isEnabled && !item.isArchived)
          .toList();

  @override
  Future<List<RoutineDefinition>> getAllManagedRoutines() async =>
      _definitions.values.where((item) => !item.isArchived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<List<RoutineDefinition>> getAllRoutineDefinitions() async =>
      _definitions.values.toList(growable: false);

  @override
  Future<CalendarDay?> getEarliestRoutineCreationDay() async {
    if (_definitions.isEmpty) return null;
    final earliest = _definitions.values
        .map((item) => CalendarDay.fromDateTime(item.createdAt.toLocal()))
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    return earliest;
  }

  @override
  Future<List<RoutineStepDefinition>> getSteps(String routineId) async => _steps
      .values
      .where((step) => step.routineId == routineId && !step.isArchived)
      .toList(growable: false);

  @override
  Future<List<RoutineStepDefinition>> getAllStepsIncludingArchived(
    String routineId,
  ) async => _steps.values
      .where((step) => step.routineId == routineId)
      .toList(growable: false);

  @override
  Future<List<RoutineStepDefinition>>
  getAllStepDefinitionsIncludingArchived() async =>
      _steps.values.toList(growable: false);

  @override
  Future<void> saveRoutine(
    RoutineDefinition definition, {
    List<RoutineStepDefinition>? steps,
  }) async {
    _definitions[definition.id] = definition;
    if (steps != null) {
      for (final step in steps) {
        _steps['${step.routineId}:${step.stepId}'] = step;
      }
    }
    _changes.add(null);
  }

  @override
  Future<void> setEnabled(String id, bool enabled, DateTime now) async {
    final item = _definitions[id];
    if (item != null) {
      _definitions[id] = item.copyWith(isEnabled: enabled, updatedAt: now);
      _changes.add(null);
    }
  }

  @override
  Future<void> archiveCustomRoutine(String id, DateTime now) async {
    final item = _definitions[id];
    if (item?.origin != RoutineOrigin.custom) return;
    _definitions[id] = item!.copyWith(
      isEnabled: false,
      isArchived: true,
      updatedAt: now,
    );
    _changes.add(null);
  }
}
