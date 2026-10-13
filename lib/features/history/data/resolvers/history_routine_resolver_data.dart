import '../../domain/repositories/history_routine_resolver.dart';
import '../../../routines/data/demo/routine_demo_data.dart';
import '../../../routines/data/resolvers/routine_resolver.dart';
import '../../../routines/domain/models/routine.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_origin.dart';
import '../../../routines/domain/models/routine_step_definition.dart';
import '../../domain/models/history_day.dart';

class HistoryRoutineResolverData implements HistoryRoutineResolver {
  const HistoryRoutineResolverData();

  @override
  Routine? resolve(
    RoutineDefinition definition,
    List<RoutineStepDefinition> stepDefinitions,
  ) {
    if (definition.origin == RoutineOrigin.defaultRoutine) {
      return RoutineDemoData.byId(definition.templateKey ?? definition.id) ??
          Routine(
            id: definition.id,
            title: definition.title,
            description: definition.description ?? '',
            preferredTime: '',
            contextLabel: '',
            isOptional: !mandatoryPrayerIds.contains(definition.id),
            steps: const [],
          );
    }
    final sorted = [...stepDefinitions]
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.createdAt.compareTo(b.createdAt);
      });
    return Routine(
      id: definition.id,
      title: definition.title,
      description: definition.description ?? '',
      preferredTime: '',
      contextLabel: '',
      isOptional: true,
      steps: [for (final step in sorted) routineStepFromDefinition(step)],
    );
  }
}
