import '../models/routine.dart';
import '../models/routine_status.dart';

class ResolveRoutineStatusUseCase {
  const ResolveRoutineStatusUseCase();

  RoutineStatus call({
    required Routine routine,
    required Set<String> completedStepIds,
    bool notToday = false,
  }) {
    if (notToday) return RoutineStatus.notToday;
    final requiredSteps = routine.steps.where((step) => step.isRequired);
    final completedRequired = requiredSteps
        .where((step) => completedStepIds.contains(step.id))
        .length;
    if (completedRequired == 0) return RoutineStatus.pending;
    if (completedRequired ==
        routine.steps.where((step) => step.isRequired).length) {
      return RoutineStatus.completed;
    }
    return RoutineStatus.partial;
  }
}
