import '../../domain/models/routine.dart';
import '../../domain/models/routine_definition.dart';
import '../../domain/models/routine_origin.dart';
import '../../domain/models/routine_requirement.dart';
import '../../domain/models/routine_schedule.dart';
import '../../domain/models/routine_step.dart';
import '../../domain/models/routine_step_definition.dart';
import '../../domain/repositories/routine_repository.dart';
import '../demo/routine_demo_data.dart';

class ResolvedRoutine {
  const ResolvedRoutine({required this.definition, required this.routine});
  final RoutineDefinition definition;
  final Routine routine;
}

class RoutineResolver {
  const RoutineResolver(this.repository);
  final RoutineRepository repository;

  Future<ResolvedRoutine?> resolve(String id) async {
    final definition = await repository.getRoutine(id);
    if (definition == null || definition.isArchived) return null;
    if (definition.origin == RoutineOrigin.defaultRoutine) {
      final template = RoutineDemoData.byId(definition.templateKey ?? id);
      if (template == null) return null;
      final preferredTime = switch (definition.schedule) {
        FixedRoutineSchedule(:final value) => formatRoutineMinutes(value),
        PrayerRoutineSchedule() => '',
      };
      return ResolvedRoutine(
        definition: definition,
        routine: Routine(
          id: template.id,
          title: template.title,
          description: definition.description ?? template.description,
          preferredTime: preferredTime,
          contextLabel: template.contextLabel,
          isOptional: template.isOptional,
          steps: template.steps,
          illustrationAsset: template.illustrationAsset,
        ),
      );
    }
    final definitions = await repository.getSteps(id);
    return ResolvedRoutine(
      definition: definition,
      routine: Routine(
        id: definition.id,
        title: definition.title,
        description: definition.description ?? '',
        preferredTime: switch (definition.schedule) {
          FixedRoutineSchedule(:final value) => formatRoutineMinutes(value),
          PrayerRoutineSchedule() => '',
        },
        contextLabel: '',
        isOptional: true,
        steps: [
          for (final step in definitions) routineStepFromDefinition(step),
        ],
      ),
    );
  }
}

RoutineStep routineStepFromDefinition(RoutineStepDefinition step) =>
    RoutineStep(
      id: step.stepId,
      title: step.title,
      subtitle: '',
      requirement: step.isRequired
          ? RoutineRequirement.required
          : RoutineRequirement.optional,
    );

String formatRoutineMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
