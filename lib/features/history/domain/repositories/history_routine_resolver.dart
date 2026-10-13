import '../../../routines/domain/models/routine.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_step_definition.dart';

abstract interface class HistoryRoutineResolver {
  Routine? resolve(
    RoutineDefinition definition,
    List<RoutineStepDefinition> stepDefinitions,
  );
}
