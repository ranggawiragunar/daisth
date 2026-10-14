import '../models/routine_content.dart';

abstract interface class RoutineContentRepository {
  Future<RoutineContent?> getForRoutine(String routineId);
  Future<void> save(RoutineContent content);
  Future<void> deleteForRoutine(String routineId, {required DateTime now});
}
