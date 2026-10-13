import '../models/routine_definition.dart';
import '../models/routine_step_definition.dart';

abstract interface class RoutineRepository {
  Stream<void> get changes;
  Future<RoutineDefinition?> getRoutine(String id);
  Future<List<RoutineDefinition>> getActiveRoutines();
  Future<List<RoutineDefinition>> getAllManagedRoutines();
  Future<List<RoutineStepDefinition>> getSteps(String routineId);
  Future<void> saveRoutine(
    RoutineDefinition definition, {
    List<RoutineStepDefinition>? steps,
  });
  Future<void> setEnabled(String id, bool enabled, DateTime now);
  Future<void> archiveCustomRoutine(String id, DateTime now);
}
