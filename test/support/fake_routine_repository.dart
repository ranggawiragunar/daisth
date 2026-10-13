import 'dart:async';

import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_step_definition.dart';
import 'package:daisth/features/routines/domain/repositories/routine_repository.dart';

class FakeRoutineRepository implements RoutineRepository {
  FakeRoutineRepository({List<RoutineDefinition>? definitions}) {
    for (final definition
        in definitions ??
            DefaultRoutineTemplateCatalog.definitions(
              DateTime.utc(2026, 10, 13),
            )) {
      _definitions[definition.id] = definition;
    }
  }

  final Map<String, RoutineDefinition> _definitions = {};
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
  Future<List<RoutineStepDefinition>> getSteps(String routineId) async =>
      const [];

  @override
  Future<void> saveRoutine(
    RoutineDefinition definition, {
    List<RoutineStepDefinition>? steps,
  }) async {
    _definitions[definition.id] = definition;
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
