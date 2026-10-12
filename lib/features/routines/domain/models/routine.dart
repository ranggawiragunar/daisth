import 'routine_step.dart';

class Routine {
  Routine({
    required this.id,
    required this.title,
    required this.description,
    required this.preferredTime,
    required this.contextLabel,
    required this.isOptional,
    required List<RoutineStep> steps,
    this.illustrationAsset,
  }) : steps = List.unmodifiable(steps);

  final String id;
  final String title;
  final String description;
  final String preferredTime;
  final String contextLabel;
  final bool isOptional;
  final List<RoutineStep> steps;
  final String? illustrationAsset;

  bool get isComposite => steps.length > 1;
}
